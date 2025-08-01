/*  HBQueueDetailsViewController.h $

 This file is part of the HandBrake source code.
 Homepage: <http://handbrake.fr/>.
 It may be used under the terms of the GNU General Public License. */

#import <Cocoa/Cocoa.h>
#import "HBQueueItem.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HBQueueDetailsViewControllerDelegate

- (void)detailsViewEditItem:(id<HBQueueItem>)item;
- (void)detailsViewResetItem:(id<HBQueueItem>)item;

@end

@interface HBQueueInfoViewController : NSViewController

- (instancetype)initWithDelegate:(id<HBQueueDetailsViewControllerDelegate>)delegate;

@property (nonatomic) id<HBQueueItem> item;

@end

NS_ASSUME_NONNULL_END
