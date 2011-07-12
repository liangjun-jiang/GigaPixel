//
//  SearchViewController.m
//  Pathology-interface
//
//  Created by Liangjun Jiang on 7/12/11.
//  Copyright 2011 Harvard University Extension School. All rights reserved.
//

#import "SearchViewController.h"
#import "GigaPixelViewController.h"

@implementation SearchViewController
@synthesize searchResults;


-(void)setPopup:(UIPopoverController*)p
{
	popoverController = p;
}

-(BOOL)performSeachWithKeyword:(NSString *)searchString
{
    [searchResults release];
    searchResults = nil;
    NSArray *keywordArray = [keywordLibrary allKeys];
    NSMutableArray *results = [NSMutableArray array];
    for (NSString *keyword in keywordArray) {
        if ([keyword isKindOfClass:[NSString class]]) {
            NSRange range = [keyword rangeOfString:searchString];
            if ((range.location != NSNotFound)){
                [results addObject:keyword];
            }
       }
    }   
    if ([results count] == 0) {
        [results addObject:@"No Results"];
    }
    searchResults = [[NSArray alloc] initWithArray:results];
    [self.tableView reloadData];
    return YES;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Initialize the searchbar and title
        self.view.frame = [[UIScreen mainScreen] applicationFrame];
        self.view.autoresizesSubviews = YES;
        
        keywordSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)];
        keywordSearchBar.placeholder = @"Search";
        keywordSearchBar.delegate = self;
        keywordSearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        [keywordSearchBar sizeToFit];
        
        [keywordSearchBar becomeFirstResponder];
        
        self.tableView.tableHeaderView = keywordSearchBar;
        
        keywordLibrary = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GigaPixel" ofType:@"plist"]];
        searchResults = nil;
        
    }
    return self;
}

#pragma UISearchBarDelegate methods
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self performSeachWithKeyword:searchBar.text];
}

- (void)dealloc
{
    searchResults = nil;
    [searchResults release];
   
    keywordLibrary = nil;
    [keywordLibrary release];
    
    keywordSearchBar = nil;
    [keywordSearchBar release];
    
    [popoverController release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = YES;
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [searchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if ([searchResults count] != 0) {
        cell.textLabel.text = [searchResults objectAtIndex:indexPath.row];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GigaPixelViewController *vc =[[[GigaPixelViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    vc.gigapixelIdentifier = [[searchResults objectAtIndex:indexPath.row] intValue];
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentModalViewController:vc animated:YES];
}

@end
