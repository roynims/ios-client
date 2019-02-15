//
//  GetTreatmentViewController.m
//  ExampleObjc
//
//  Created by Javier L. Avrudsky on 27/11/2018.
//  Copyright © 2018 Split Software. All rights reserved.
//

#import "GetTreatmentViewController.h"
@import Split;

@interface GetTreatmentViewController ()

@property (weak, nonatomic) IBOutlet UITextField *splitNameField;
@property (weak, nonatomic) IBOutlet UITextField *matchingKeyField;
@property (weak, nonatomic) IBOutlet UITextField *bucketingKeyField;
@property (weak, nonatomic) IBOutlet UITextField *attributesField;

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UIButton *evaluateButton;

@end

@implementation GetTreatmentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)evaluateDidTouch:(UIButton *)sender {
    
    NSString *apiKey = @"YOUR_API_KEY";
    NSString *splitName = self.splitNameField.text;
    NSString *matchingKey = self.matchingKeyField.text;
    
    // Split Config
    SplitClientConfig *config = [[SplitClientConfig alloc] init];
    config.featuresRefreshRate = 30;
    config.segmentsRefreshRate = 30;
    config.impressionRefreshRate = 30;
    config.sdkReadyTimeOut = 15000;
    config.connectionTimeout = 50;
    
    // Impression listener
    config.impressionListener = ^(Impression *impression){
        NSLog(@"Impression Key: %@", impression.keyName);
        NSLog(@"Impression Treatment: %@", impression.treatment);
        NSLog(@"Impression Time: %@", impression.timestamp);
        NSLog(@"Impression Change Number: %@", impression.changeNum);
    };
    
    //User Key
    Key *key = [[Key alloc] initWithMatchingKey:matchingKey bucketingKey:nil];
    
    //Split Factory
    id<SplitFactoryBuilder> builder = [[DefaultSplitFactoryBuilder alloc] init];
    [builder setApiKey: apiKey];
    [builder setKey: key];
    [builder setConfig: config];
    
    id<SplitFactory> factory = [builder build];
    
    //Showing sdk version in UI
    self.versionLabel.text = factory.version;
    
    //Split Client
    id<SplitClient> client = factory.client;
    
    //Split Manager
    id<SplitManager>manager = factory.manager;
    
    [client onEvent: SplitEventSdkReady execute: ^(){
        
        NSDictionary *attributes = [self convertToDictionary:self.attributesField.text];
        self.resultLabel.text = [client getTreatment:splitName attributes: attributes];
        
        // Get All Splits
        NSArray *splits = manager.splits;
        for(SplitView *split in splits) {
            NSLog(@"SplitView: %@, treatments: %@", split.name, [split.treatments componentsJoinedByString:@","]);
        }
        
        // Get Splits Names
        NSArray *splitNames = manager.splitNames;
        for(SplitView *splitName in splitNames) {
            NSLog(@"Split Name: %@", splitName);
        }
        
        // Find a Split
        if(splitNames.count > 0) {
            SplitView *split = [manager splitWithFeatureName:splitNames[0]];
            NSLog(@"Found: %@, treatments: %@", split.name, [split.treatments componentsJoinedByString:@","]);
        }
    }];
    
    [client onEvent: SplitEventSdkReadyTimedOut execute: ^(){
        self.resultLabel.text = @"SDK Time Out";
    }];
}

- ( NSDictionary* _Nullable ) convertToDictionary:(NSString*) text {
    NSData *data = [text dataUsingEncoding: kCFStringEncodingUTF8];
    if( data == nil) return nil;
    NSError *error = nil;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if(error != nil) {
        NSLog(@"Error parsing attributes: %@", error.localizedDescription);
        return nil;
    }
    return jsonObject;
}

@end
