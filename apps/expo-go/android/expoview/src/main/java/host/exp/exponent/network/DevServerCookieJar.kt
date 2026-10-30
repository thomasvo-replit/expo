// Copyright 2015-present 650 Industries. All rights reserved.
package host.exp.exponent.network

import android.webkit.CookieManager
import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.HttpUrl

/**
 * Cookies set by development servers, so a server behind a login can exchange a token for a
 * session cookie on the first request and receive it on the manifest, status, bundle, asset, and
 * WebSocket requests that follow.
 *
 * Cookies are stored and returned only for the exact origin (scheme, host, and port) that set them,
 * so two dev servers on the same host never share credentials through this jar. They are kept in
 * memory for the life of the process.
 */
object DevServerCookieJar : CookieJar {
  private val cookiesByOrigin = mutableMapOf<String, MutableList<Cookie>>()

  @Synchronized
  override fun saveFromResponse(url: HttpUrl, cookies: List<Cookie>) {
    val stored = cookiesByOrigin.getOrPut(originOf(url)) { mutableListOf() }
    for (cookie in cookies) {
      stored.removeAll { it.name == cookie.name && it.path == cookie.path }
      stored.add(cookie)
    }
    copyToProjectCookieStore(url, cookies)
  }

  // Fast Refresh opens its /hot WebSocket from JavaScript through React Native's WebSocketModule,
  // which only reads the project's cookie store. Copying the dev server's cookies there, for the
  // dev server's own URL, lets that connection authenticate too.
  private fun copyToProjectCookieStore(url: HttpUrl, cookies: List<Cookie>) {
    try {
      val cookieManager = CookieManager.getInstance()
      for (cookie in cookies) {
        cookieManager.setCookie(url.toString(), cookie.toString())
      }
      cookieManager.flush()
    } catch (e: Exception) {
      // CookieManager is unavailable when the WebView package is missing or updating.
    }
  }

  @Synchronized
  override fun loadForRequest(url: HttpUrl): List<Cookie> {
    val stored = cookiesByOrigin[originOf(url)] ?: return emptyList()
    val now = System.currentTimeMillis()
    stored.removeAll { it.expiresAt < now }
    return stored.filter { it.matches(url) }
  }

  private fun originOf(url: HttpUrl) = "${url.scheme}://${url.host}:${url.port}"
}
