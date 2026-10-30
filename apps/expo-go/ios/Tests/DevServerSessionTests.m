// Copyright 2015-present 650 Industries. All rights reserved.

#import <XCTest/XCTest.h>
#import "../Exponent/Kernel/AppLoader/EXAppLoaderExpoUpdates.h"

// Exercise the loader's URL boundaries without exposing test-only production API.
@interface EXAppLoaderExpoUpdates (DevServerSessionTests)
+ (NSURL *)_sessionUrlFromManifestUrl:(NSURL *)url;
+ (NSURL *)_httpUrlFromManifestUrl:(NSURL *)url;
@end

@interface DevServerSessionTests : XCTestCase
@end

@implementation DevServerSessionTests

- (void)testBootstrapPreservesEncodedQueryAndRemovesFragment
{
  NSURL *url = [NSURL URLWithString:@"exp://localhost:8081/?token=a%2Bb%26c&other=1&other=2#screen"];
  XCTAssertEqualObjects([EXAppLoaderExpoUpdates _sessionUrlFromManifestUrl:url].absoluteString,
                        @"http://localhost:8081/?token=a%2Bb%26c&other=1&other=2");
  XCTAssertEqualObjects([EXAppLoaderExpoUpdates _httpUrlFromManifestUrl:url].absoluteString,
                        @"http://localhost:8081/");
}

- (void)testCanonicalUrlKeepsProjectIdentityParameters
{
  NSURL *url = [NSURL URLWithString:@"exps://example.test/project?token=secret&release-channel=preview&runtime-version=58&channel-name=dev&snack-channel=abc"];
  XCTAssertEqualObjects([EXAppLoaderExpoUpdates _sessionUrlFromManifestUrl:url].absoluteString,
                        @"https://example.test/project?token=secret&release-channel=preview&runtime-version=58&channel-name=dev&snack-channel=abc");
  XCTAssertEqualObjects([EXAppLoaderExpoUpdates _httpUrlFromManifestUrl:url].absoluteString,
                        @"https://example.test/project?release-channel=preview&runtime-version=58&channel-name=dev&snack-channel=abc");
}

- (void)testDifferentTokensHaveTheSameCanonicalUrl
{
  NSURL *first = [NSURL URLWithString:@"exp://localhost:8081/?token=first"];
  NSURL *second = [NSURL URLWithString:@"exp://localhost:8081/?token=second"];
  XCTAssertEqualObjects([EXAppLoaderExpoUpdates _httpUrlFromManifestUrl:first],
                        [EXAppLoaderExpoUpdates _httpUrlFromManifestUrl:second]);
}

- (void)testCanonicalQueryPreservesEncodedIdentityValuesAndDuplicateItems
{
  NSURL *url = [NSURL URLWithString:@"exp://localhost:8081/?token=secret&release%2Dchannel=a%2Bb%26c%3Dd%20e&channel-name=first&channel-name=second"];
  XCTAssertEqualObjects([EXAppLoaderExpoUpdates _httpUrlFromManifestUrl:url].absoluteString,
                        @"http://localhost:8081/?release%2Dchannel=a%2Bb%26c%3Dd%20e&channel-name=first&channel-name=second");
}

- (void)testNormalUrlsDoNotBootstrap
{
  for (NSString *value in @[
    @"exp://localhost:8081/",
    @"exps://example.test/project",
    @"exp://localhost:8081/?release-channel=preview&runtime-version=58&channel-name=dev&snack-channel=abc"
  ]) {
    NSURL *url = [NSURL URLWithString:value];
    XCTAssertNil([EXAppLoaderExpoUpdates _sessionUrlFromManifestUrl:url]);
  }
}

- (void)testHttpAndHttpsKeepTheirTransport
{
  for (NSString *scheme in @[@"http", @"https"]) {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://example.test/?token=secret", scheme]];
    XCTAssertEqualObjects([EXAppLoaderExpoUpdates _sessionUrlFromManifestUrl:url], url);
    XCTAssertEqualObjects([EXAppLoaderExpoUpdates _httpUrlFromManifestUrl:url].absoluteString,
                          [NSString stringWithFormat:@"%@://example.test/", scheme]);
  }
}

- (void)testIdentityOnlyQueryKeepsExistingEncodingAndFragment
{
  NSURL *url = [NSURL URLWithString:@"exp://localhost:8081/?release-channel=a%2Bb#details"];
  XCTAssertNil([EXAppLoaderExpoUpdates _sessionUrlFromManifestUrl:url]);
  XCTAssertEqualObjects([EXAppLoaderExpoUpdates _httpUrlFromManifestUrl:url].absoluteString,
                        @"http://localhost:8081/?release-channel=a%2Bb#details");
}

- (void)testModernAndLegacyDeepLinksKeepExistingBehavior
{
  for (NSString *path in @[@"/--/screen", @"/+screen"]) {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"exp://localhost:8081%@?item=1#details", path]];
    XCTAssertNil([EXAppLoaderExpoUpdates _sessionUrlFromManifestUrl:url]);
    XCTAssertEqualObjects([EXAppLoaderExpoUpdates _httpUrlFromManifestUrl:url].absoluteString,
                          @"http://localhost:8081/?item=1#details");
  }
}

@end
