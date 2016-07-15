//
//  main.m
//  generate-string-symbols
//
//  Created by Daniel Kennett on 07/08/14.
//  For license information, see LICENSE.markdown

#import <Foundation/Foundation.h>

#pragma mark - Usage

void printUsage() {

    NSString *processName = [[NSProcessInfo processInfo] processName];
    NSString *processNamePadding = [@"" stringByPaddingToLength:processName.length
                                                     withString:@" "
                                                startingAtIndex:0];

    printf("%s by Daniel Kennett\n\n", processName.UTF8String);

    printf("Outputs a header file containing symbols for the given .xcassets\n");
    printf("folder's images.\n\n");

    printf("Usage: %s -assets <xcassets file path>\n", processName.UTF8String);
    printf("       %s -out <output file path> \n", processNamePadding.UTF8String);
    printf("       %s -prefix <string> \n", processNamePadding.UTF8String);
    printf("       %s -suffix <string> \n", processNamePadding.UTF8String);
    printf("       %s -skipwriteifunchanged <YES/NO> \n\n", processNamePadding.UTF8String);

    printf("  -assets  The path to a valid .xcassets folder.\n\n");

    printf("  -out      The path to write the output header file to. Missing\n");
    printf("            directories will be created along the way. If a file\n");
    printf("            already exists at the given path, it will be\n");
    printf("            overwritten.\n\n");

    printf("  -prefix   A string to prefix the generated symbol names with.\n\n");

    printf("  -prefix   A string to prefix the generated symbol names with.\n\n");

    printf("  -skipwriteifunchanged   Pass YES to this to skip output writing\n");
    printf("                          if a file already exists at -out with the \n");
    printf("                          same contents as would be written.");

    printf("\n\n");
}

#pragma mark - Main

NSString *sanitisedSymbolStringForString(NSString *string) {
    if (string == nil) { return @""; }
    NSCharacterSet *unwantedThings = [NSCharacterSet characterSetWithCharactersInString:@"\t\n -/"];
    return [[string componentsSeparatedByCharactersInSet:unwantedThings] componentsJoinedByString:@""];
}

int main(int argc, const char * argv[])
{

    @autoreleasepool {

        NSString *inputFilePath = [[NSUserDefaults standardUserDefaults] valueForKey:@"assets"];
        NSString *outputFilePath = [[NSUserDefaults standardUserDefaults] valueForKey:@"out"];
        NSString *namePrefix = sanitisedSymbolStringForString([[NSUserDefaults standardUserDefaults] valueForKey:@"prefix"]);
        NSString *nameSuffix = sanitisedSymbolStringForString([[NSUserDefaults standardUserDefaults] valueForKey:@"suffix"]);
        BOOL skipWriteIfUnchanged = [[NSUserDefaults standardUserDefaults] boolForKey:@"skipwriteifunchanged"];
        NSFileManager *fileManager = [NSFileManager defaultManager];

        setbuf(stdout, NULL);

        if (inputFilePath.length == 0 || outputFilePath.length == 0) {
            printUsage();
            exit(EXIT_FAILURE);
        }

        BOOL isDirectory = NO;
        if (![fileManager fileExistsAtPath:inputFilePath isDirectory:&isDirectory] || !isDirectory) {
            printf("ERROR: Input folder %s doesn't exist.\n", [inputFilePath UTF8String]);
            exit(EXIT_FAILURE);
        }


        // Enumerate directory for .imageset folders
        NSMutableArray *names = [NSMutableArray new];
        NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:inputFilePath];

        for (NSString *name in enumerator) {
            if ([name.pathExtension isEqualToString:@"imageset"]) {
                [names addObject:name.lastPathComponent.stringByDeletingPathExtension];
                [enumerator skipDescendants];
            }
        }

        NSMutableString *fileContents = [NSMutableString new];

        [fileContents appendFormat:@"// Generated by %@.\n", [[NSProcessInfo processInfo] processName]];
        [fileContents appendFormat:@"// Source file: %@\n", inputFilePath];
        [fileContents appendString:@"// WARNING: This file was auto-generated. Do not modify by hand.\n\n"];

        [fileContents appendString:@"#import <Foundation/Foundation.h>\n\n"];

        for (NSString *name in names) {
            [fileContents appendString:[NSString stringWithFormat:@"static NSString * const %@%@%@ = @\"%@\";\n", namePrefix, name, nameSuffix, name]];
        }

        NSError *error = nil;
        NSString *parentPath = [outputFilePath stringByDeletingLastPathComponent];
        if (![fileManager fileExistsAtPath:parentPath]) {
            if (![fileManager createDirectoryAtPath:parentPath
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:&error]) {
                printf("ERROR: Creating parent directory failed with error: %s\n", error.localizedDescription.UTF8String);
                exit(EXIT_FAILURE);
            }
        }

        NSData *dataToWrite = [fileContents dataUsingEncoding:NSUTF8StringEncoding];

        if (skipWriteIfUnchanged && [fileManager fileExistsAtPath:outputFilePath]) {
            NSData *existingData = [NSData dataWithContentsOfFile:outputFilePath];

            if (existingData != nil && [dataToWrite isEqual:existingData]) {
                printf("File already exists at -out with the same contents as we'd write. Skipping.\n");
                exit(EXIT_SUCCESS);
            }
        }

        if (![dataToWrite writeToFile:outputFilePath options:NSDataWritingAtomic error:&error]) {
            printf("ERROR: Writing output file failed with error: %s\n", error.localizedDescription.UTF8String);
            exit(EXIT_FAILURE);
        }

        exit(EXIT_SUCCESS);

    }
    return 0;
}