//
//  Copyright (c) 2015-Present Oleg Hnidets
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

@import Foundation;
@class OHMySQLQueryContext, OHMySQLStoreCoordinator;

NS_SWIFT_NAME(MySQLContainer)
/// Represents a main context and store coordinator.
@interface OHMySQLContainer : NSObject

/// The shared container.
@property (class, strong, readonly, nonnull) OHMySQLContainer *shared;

/// Main context that is used in the app. Context must be set by the client of this class.
@property (nonatomic, strong, nullable) OHMySQLQueryContext *mainQueryContext;

/// Main store coordinator.
@property (nonatomic, strong, readonly, nullable) OHMySQLStoreCoordinator *storeCoordinator;

@end
