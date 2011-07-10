//Session List Axel Hansen


@interface SessionList : UITableViewController {
    NSMutableDictionary *sessions;
	NSMutableArray *sessionArray;
	id  glview;
	UIPopoverController *popup;
	struct Messages* data;
	int type;
	
}
@end
