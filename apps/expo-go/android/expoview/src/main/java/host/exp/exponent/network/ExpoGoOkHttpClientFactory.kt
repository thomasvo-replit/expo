// Copyright 2015-present 650 Industries. All rights reserved.
package host.exp.exponent.network

import com.facebook.react.modules.network.OkHttpClientFactory
import com.facebook.react.modules.network.ReactCookieJarContainer
import expo.modules.kotlin.devtools.ExpoNetworkInspectOkHttpAppInterceptor
import expo.modules.kotlin.devtools.ExpoNetworkInspectOkHttpNetworkInterceptor
import okhttp3.OkHttpClient
import java.util.concurrent.TimeUnit

/**
 * Supplies the OkHttp client React Native uses for networking, so that every client it creates shares
 * Expo Go's single response cache rather than opening one of its own.
 */
class ExpoGoOkHttpClientFactory(private val exponentNetwork: ExponentNetwork) : OkHttpClientFactory {
  override fun createNewNetworkModuleClient(): OkHttpClient =
    OkHttpClient.Builder()
      .connectTimeout(0, TimeUnit.MILLISECONDS)
      .readTimeout(0, TimeUnit.MILLISECONDS)
      .writeTimeout(0, TimeUnit.MILLISECONDS)
      // The container drops cookies until a jar is installed, and NetworkingModule only replaces it
      // for the project's own networking client. Manifest, bundle, and dev server requests keep this one.
      .cookieJar(ReactCookieJarContainer().apply { setCookieJar(DevServerCookieJar) })
      .cache(exponentNetwork.cache)
      .addInterceptor(ExpoNetworkInspectOkHttpAppInterceptor())
      .addNetworkInterceptor(ExpoNetworkInspectOkHttpNetworkInterceptor())
      .build()
}
