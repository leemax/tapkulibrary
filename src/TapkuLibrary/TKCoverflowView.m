//
//  TKCoverflowView.m
//  Created by Devin Ross on 1/3/10.
//
/*
 
 tapku.com || http://github.com/devinross/tapkulibrary
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
*/

#import "TKCoverflowView.h"
#import "TKCoverView.h"
#import "TKGlobal.h"

#define COVER_SPACING 50.0
#define CENTER_COVER_OFFSET 70
#define SIDE_COVER_ANGLE 1.4
#define SIDE_COVER_ZPOSITION -80
#define COVER_SCROLL_PADDING 4
#define COVER_SPACING_MAIN 240

@interface TKCoverflowView (hidden)

- (void) animateToIndex:(int)index  animated:(BOOL)animated;
- (void) load;
- (void) setup;
- (void) newrange;

- (void) deplaceAlbumsFrom:(int)start to:(int)end;
- (void) deplaceAlbumsAtIndex:(int)cnt;
- (BOOL) placeAlbumsFrom:(int)start to:(int)end;
- (void) placeAlbumAtIndex:(int)cnt;

- (void) snapToAlbum;

@end

@implementation TKCoverflowView (hidden)


- (void) load{
	

	coverSize = CGSizeMake(224, 224);
	
	leftTransform = CATransform3DIdentity;
	leftTransform = CATransform3DRotate(leftTransform, angle, 0.0f, 1.0f, 0.0f);
	leftTransform = CATransform3DScale(leftTransform,1,1,1);
	leftTransform = CATransform3DTranslate(leftTransform, COVER_SPACING_MAIN, 0,-150);
	
	rightTransform = CATransform3DIdentity;
	rightTransform = CATransform3DRotate(rightTransform, angle, 0.0f, -1.0f, 0.0f);
	rightTransform = CATransform3DScale(rightTransform,1,1,1);
	rightTransform = CATransform3DTranslate(rightTransform, -1 * COVER_SPACING_MAIN, 0,-150);
	
	
	CATransform3D sublayerTransform = CATransform3DIdentity;
	sublayerTransform.m34 = -0.001;
	[self.layer setSublayerTransform:sublayerTransform];
	
	margin = (self.frame.size.width / 2);
	

	yard = [[NSMutableArray alloc] init];
	views = [[NSMutableArray alloc] init];
	
	
}
- (void) setup{

	currentIndex = -1;
	for(UIView *v in views) [v removeFromSuperview];
	[yard removeAllObjects];
	[views removeAllObjects];
	[coverViews release];
	
	if(numberOfCovers < 1) return;
	
	self.contentSize = CGSizeMake( (coverSpacing) * (numberOfCovers-1) + (margin*2) , self.frame.size.height);
	coverBuffer = (int) ((self.frame.size.width - coverSize.width) / coverSpacing) + 3;
	

	coverViews = [[NSMutableArray alloc] initWithCapacity:numberOfCovers];
	for (unsigned i = 0; i < numberOfCovers; i++) [coverViews addObject:[NSNull null]];
	deck = NSMakeRange(0, 0);
	movingRight = YES;
	
	//[self placeAlbumsFrom:deck.location to:deck.length transform:rightTransform];
	
	

	
	currentIndex = 0;
	[self newrange];
	[self animateToIndex:currentIndex animated:NO];
	
}


- (void) deplaceAlbumsFrom:(int)start to:(int)end{
	
	if(start >= end) return;
	
	for(int cnt=start;cnt<end;cnt++){
		[self deplaceAlbumsAtIndex:cnt];
	}
	
		
}
- (void) deplaceAlbumsAtIndex:(int)cnt{
	if(cnt >= [coverViews count]) return;
	
	
	
	if([coverViews objectAtIndex:cnt] != [NSNull null]  ){
		
		UIView *v = [coverViews objectAtIndex:cnt];
		[v removeFromSuperview];
		[views removeObject:v];
		[yard addObject:v];
		[coverViews replaceObjectAtIndex:cnt withObject:[NSNull null]];
		
	}
}

- (BOOL) placeAlbumsFrom:(int)start to:(int)end{
	
	if(start >= end) return NO;
	
	for(int cnt=start;cnt<= end;cnt++) [self placeAlbumAtIndex:cnt];
	
	return YES;
	
	
}
- (void) placeAlbumAtIndex:(int)cnt{
	
	if(cnt >= [coverViews count]) return;
	
	
	if([coverViews objectAtIndex:cnt] == [NSNull null]){
		
		TKCoverView *cover = [dataSource coverflowView:self coverAtIndex:cnt];
		[coverViews replaceObjectAtIndex:cnt withObject:cover];
		
		CGRect r = cover.frame;
		r.origin.y = self.bounds.size.height / 2 - (coverSize.height/2) - (coverSize.height/16);
		r.origin.x = (self.frame.size.width/2 - (coverSize.width/ 2)) + (coverSpacing) * cnt;
		cover.frame = r;
		
		
		[self addSubview:cover];
		if(cnt > currentIndex){
			cover.layer.transform = rightTransform;
			[self sendSubviewToBack:cover];
		}
		else 
			cover.layer.transform = leftTransform;
		
		[views addObject:cover];
		
	}
}

- (void) newrange{
	
	
	
	int loc = deck.location, len = deck.length, buff = coverBuffer;
	
	int newLocation = currentIndex - buff < 0 ? 0 : currentIndex-buff;
	int newLength = currentIndex + buff > numberOfCovers ? numberOfCovers - newLocation : currentIndex + buff - newLocation;
	
	
	
	
	if(loc == newLocation && newLength == len) return;
		
	if(movingRight){
		[self deplaceAlbumsFrom:loc to:MIN(newLocation,loc+len)];
		[self placeAlbumsFrom:MAX(loc+len,newLocation) to:newLocation+newLength];
		
	}else{
		[self deplaceAlbumsFrom:MAX(newLength+newLocation,loc) to:loc+len];
		[self placeAlbumsFrom:newLocation to:MIN(loc,newLocation+newLength)];
	}
	
	deck = NSMakeRange(newLocation, newLength);
	
	
}

- (void) snapToAlbum{
	
	float scroll_size = self.contentSize.width - self.frame.size.width;
	int covers_per = scroll_size / (numberOfCovers-1);
	float v = (currentIndex * covers_per) - (covers_per/2) + (coverSpacing/2);
	[self setContentOffset:CGPointMake(v, 0) animated:YES];
}


- (void) animateToIndex:(int)index animated:(BOOL)animated{
	
	
	NSString *string = [NSString stringWithFormat:@"%d",currentIndex];
	if(velocity> 180) animated = NO;
	
	if(animated){
		
		float speed = 0.3;
		speed = velocity > 15 ? 0.2 :speed;
		speed = velocity > 25 ? 0.08 :speed;
		speed = velocity > 40 ? 0.03 :speed;
		speed = velocity > 80 ? 0.01 :speed;
		
		[UIView beginAnimations:string context:nil];
		[UIView setAnimationDuration:speed];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)]; 
	}

	for(UIView *v in views){
		int i = [coverViews indexOfObject:v];
		if(i < index) v.layer.transform = leftTransform;
		else if(i > index) v.layer.transform = rightTransform;
		else v.layer.transform = CATransform3DIdentity;
	}
	
	if(animated) [UIView commitAnimations];
	else [delegate coverflowView:self coverAtIndexWasBroughtToFront:currentIndex];

}

- (void) animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context{

	int i = currentIndex-1;

	for(;i > deck.location;i--){
		[self sendSubviewToBack:[coverViews objectAtIndex:i]];
	}
	
	i = currentIndex+1;
	for(;i < deck.location+deck.length;i++){
		[self bringSubviewToFront:[coverViews objectAtIndex:i]];
	}

	[self bringSubviewToFront:[coverViews objectAtIndex:currentIndex]];
	
	if([finished boolValue] && [animationID intValue] == currentIndex)
		[delegate coverflowView:self coverAtIndexWasBroughtToFront:currentIndex];
	
}

@end

@implementation TKCoverflowView
@synthesize delegate,dataSource,coverSize,numberOfCovers,coverSpacing,angle;


- (id) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		
		

		numberOfCovers = 0;
		coverSpacing = COVER_SPACING;
		angle = SIDE_COVER_ANGLE;
		
		//self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.showsHorizontalScrollIndicator = NO;
		super.delegate = self;
		origin = self.contentOffset.x;

		
		[self load];
		[self setup];

		
    }
    return self;
}


- (void) setFrame:(CGRect)r{
	[super setFrame:r];
	
	[self setContentOffset:self.contentOffset animated:YES];
	self.userInteractionEnabled = NO;
	self.scrollEnabled = NO;
	
	margin = (self.frame.size.width / 2);
	int cur = currentIndex;
	[self setup];
	
	
	self.scrollEnabled = YES;
	self.userInteractionEnabled = YES;
	
	[self animateToIndex:cur animated:NO];

}




- (void) setNumberOfCovers:(int)cov{
	
	numberOfCovers = cov;
	[self setup];
	
}
- (void) setCoverSpacing:(float)space{
	coverSpacing = space;
	
	for(UIView *cover in views){
		
		cover.layer.transform = CATransform3DIdentity;
		int index = [coverViews indexOfObject:cover];
		CGRect r = cover.frame;
		
		r.origin.y = self.bounds.size.height / 2 - (coverSize.height/2) - (coverSize.height/16);
		r.origin.x = (self.frame.size.width/2 - (coverSize.width/ 2)) + (coverSpacing) * index;
		cover.frame = r;
		
		
		if(index > currentIndex)
			cover.layer.transform = rightTransform;
		else if(index < currentIndex)
			cover.layer.transform = leftTransform;
		else
			cover.layer.transform = CATransform3DIdentity;
		
	}
	coverBuffer = (int) ((self.frame.size.width - coverSize.width) / coverSpacing) + 1;
	self.contentSize = CGSizeMake( (coverSpacing) * (numberOfCovers-1) + (margin*2) , self.frame.size.height);
	

	
	
}
- (void) setAngle:(float)f{

	angle = f;
	
	leftTransform = CATransform3DIdentity;
	leftTransform = CATransform3DRotate(leftTransform, angle, 0.0f, 1.0f, 0.0f);
	leftTransform = CATransform3DScale(leftTransform,.8,.8,1);
	leftTransform = CATransform3DTranslate(leftTransform, 120, 0,-110);
	
	rightTransform = CATransform3DIdentity;
	rightTransform = CATransform3DRotate(rightTransform, angle, 0.0f, -1.0f, 0.0f);
	rightTransform = CATransform3DScale(rightTransform,.8,.8,.5);
	rightTransform = CATransform3DTranslate(rightTransform, -10, 0,-170);
	
	
	
	[self setup];
}


- (TKCoverView *) coverAtIndex:(int)index{
	if([coverViews objectAtIndex:index] != [NSNull null]){
		return [coverViews objectAtIndex:index];
	}
	return nil;
}
- (int) indexOfFrontCoverView{
	return currentIndex;
}
- (void) bringCoverAtIndexToFront:(int)index animated:(BOOL)animated{
	[self animateToIndex:index animated:animated];
}

- (TKCoverView*) dequeueReusableCoverView{
	
	if(yard == nil || [yard count] < 1) return nil;
	
	TKCoverView *v = [[[yard lastObject] retain] autorelease];
	v.layer.transform = CATransform3DIdentity;
	[yard removeLastObject];

	return v;
}


- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	if(touch.view != self &&  [touch locationInView:touch.view].y < coverSize.height){
		currentTouch = touch.view;
	}

}
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

}
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

	UITouch *touch = [touches anyObject];
	
	if(touch.view == currentTouch){
		if(touch.tapCount > 1 && currentIndex == [coverViews indexOfObject:currentTouch]){

			if([delegate respondsToSelector:@selector(coverflowView:coverAtIndexWasDoubleTapped:)])
				[delegate coverflowView:self coverAtIndexWasDoubleTapped:currentIndex];
			
		}else{
			int index = [coverViews indexOfObject:currentTouch];
			[self setContentOffset:CGPointMake(coverSpacing*index, 0) animated:YES];
		}
		

	}
	

	
	currentTouch = nil;
}
- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
	if(currentTouch!= nil)
		currentTouch = nil;
	
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView{
	
	
	
	velocity = abs(pos - scrollView.contentOffset.x);
	pos = scrollView.contentOffset.x;
	movingRight = self.contentOffset.x - origin > 0 ? YES : NO;
	origin = self.contentOffset.x;


	int covers_per = (scrollView.contentSize.width - self.frame.size.width) / (numberOfCovers-1);
	int index = (scrollView.contentOffset.x + (covers_per/2) )/ covers_per;
	
	index = MIN(MAX(0,index),numberOfCovers-1);
	

	if(index == currentIndex) return;
	
	currentIndex = index;
	[self newrange];
	
	
	if(velocity > 180 && currentIndex > 15 && currentIndex < (numberOfCovers-16)) return;
	[self animateToIndex:index animated:YES];
	
	return;
	
}
- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView{

	if(!scrollView.tracking && !scrollView.decelerating) [self snapToAlbum];

}
- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	if(!self.decelerating && !decelerate)[self snapToAlbum];

}


- (void)drawRect:(CGRect)rect {
    // Drawing code
}

- (void)dealloc {	
	
	[coverViews release];
	[views release];
	currentTouch = nil;
	delegate = nil;
	dataSource = nil;
	
    [super dealloc];
}


@end
