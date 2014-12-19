//
//  Stripe.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 10/30/12.
//  Copyright (c) 2012 Stripe. All rights reserved.
//

#import "Stripe.h"
#import "STPAPIClient.h"
#import "STPCard.h"
#import "STPBankAccount.h"

NSString *const kStripeiOSVersion = @"2.2.2";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation Stripe (DeprecatedMethods)
#pragma clang diagnostic pop

static NSString *defaultKey;
static NSString *const apiURLBase = @"api.stripe.com";
static NSString *const apiVersion = @"v1";
static NSString *const tokenEndpoint = @"tokens";

+ (id)alloc {
    NSCAssert(NO, @"'Stripe' is a static class and cannot be instantiated.");
    return nil;
}

+ (void)createTokenWithCard:(STPCard *)card
             publishableKey:(NSString *)publishableKey
             operationQueue:(NSOperationQueue *)queue
                 completion:(STPCompletionBlock)handler {
    NSCAssert(card != nil, @"'card' is required to create a token");
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:publishableKey];
    client.operationQueue = queue;
    [client createTokenWithCard:card completion:handler];
}

+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount
                    publishableKey:(NSString *)publishableKey
                    operationQueue:(NSOperationQueue *)queue
                        completion:(STPCompletionBlock)handler {
    NSCAssert(bankAccount != nil, @"'bankAccount' is required to create a token");
    NSCAssert(handler != nil, @"'handler' is required to use the token that is created");

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:publishableKey];
    client.operationQueue = queue;
    [client createTokenWithBankAccount:bankAccount completion:handler];
}

#pragma mark Shorthand methods -

+ (void)createTokenWithCard:(STPCard *)card completion:(STPCompletionBlock)handler {
    [self createTokenWithCard:card publishableKey:[self defaultPublishableKey] completion:handler];
}

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey completion:(STPCompletionBlock)handler {
    [self createTokenWithCard:card publishableKey:publishableKey operationQueue:[NSOperationQueue mainQueue] completion:handler];
}

+ (void)createTokenWithCard:(STPCard *)card operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler {
    [self createTokenWithCard:card publishableKey:[self defaultPublishableKey] operationQueue:queue completion:handler];
}

+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount completion:(STPCompletionBlock)handler {
    [self createTokenWithBankAccount:bankAccount publishableKey:[self defaultPublishableKey] completion:handler];
}

+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount publishableKey:(NSString *)publishableKey completion:(STPCompletionBlock)handler {
    [self createTokenWithBankAccount:bankAccount publishableKey:publishableKey operationQueue:[NSOperationQueue mainQueue] completion:handler];
}

+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler {
    [self createTokenWithBankAccount:bankAccount publishableKey:[self defaultPublishableKey] operationQueue:queue completion:handler];
}

@end

@implementation STPUtils

+ (NSString *)stringByReplacingSnakeCaseWithCamelCase:(NSString *)input {
    return [STPAPIClient stringByURLEncoding:input];
}

+ (NSString *)stringByURLEncoding:(NSString *)string {
    return [STPAPIClient stringByURLEncoding:string];
}

@end
