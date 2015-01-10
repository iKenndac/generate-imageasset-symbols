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

    printf("%s by Daniel Kennett\n\n", processName.UTF8String);

    printf("Outputs a header file containing symbols for the given .xcassets\n");
    printf("folder's images.\n\n");

    printf("Usage: %s -assets <xcassets file path>\n", processName.UTF8String);
    printf("       %s -out <output file path> \n\n", [@"" stringByPaddingToLength:processName.length
                                                                     withString:@" "
                                                                startingAtIndex:0].UTF8String);

    printf("  -assets  The path to a valid .xcassets folder.\n\n");

    printf("  -out      The path to write the output header file to. Missing\n");
    printf("            directories will be created along the way. If a file\n");
    printf("            already exists at the given path, it will be\n");
    printf("            overwritten.");

    printf("\n\n");
}

#pragma mark - Main

int main(int argc, const char * argv[])
{

    @autoreleasepool {

        NSString *inputFilePath = [[NSUserDefaults standardUserDefaults] valueForKey:@"assets"];
        NSString *outputFilePath = [[NSUserDefaults standardUserDefaults] valueForKey:@"out"];

        setbuf(stdout, NULL);

        if (inputFilePath.length == 0 || outputFilePath.length == 0) {
            printUsage();
            exit(EXIT_FAILURE);
        }

        BOOL isDirectory = NO;
        if (![[NSFileManager defaultManager] fileExistsAtPath:inputFilePath isDirectory:&isDirectory] || !isDirectory) {
            printf("ERROR: Input folder %s doesn't exist.\n", [inputFilePath UTF8String]);
            exit(EXIT_FAILURE);
        }


        // Enumerate directory for .imageset folders
        NSMutableArray *names = [NSMutableArray new];
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:inputFilePath];

        for (NSString *name in enumerator) {
            if ([name.pathExtension isEqualToString:@"imageset"]) {
                [names addObject:name.stringByDeletingPathExtension];
                [enumerator skipDescendants];
            }
        }

        NSMutableString *fileContents = [NSMutableString new];

        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZZZ";

        [fileContents appendFormat:@"// Generated by %@ on %@\n", [[NSProcessInfo processInfo] processName], [formatter stringFromDate:[NSDate date]]];
        [fileContents appendFormat:@"// Source file: %@\n", inputFilePath];
        [fileContents appendString:@"// WARNING: This file was auto-generated. Do not modify by hand.\n\n"];

        [fileContents appendString:@"#import <Foundation/Foundation.h>\n\n"];

        for (NSString *name in names) {
            [fileContents appendString:[NSString stringWithFormat:@"static NSString * const %@ = @\"%@\";\n", name, name]];
        }

        NSError *error = nil;
        NSString *parentPath = [outputFilePath stringByDeletingLastPathComponent];
        if (![[NSFileManager defaultManager] fileExistsAtPath:parentPath]) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:parentPath
                                           withIntermediateDirectories:YES
                                                            attributes:nil
                                                                 error:&error]) {
                printf("ERROR: Creating parent directory failed with error: %s\n", error.localizedDescription.UTF8String);
                exit(EXIT_FAILURE);
            }
        }

        if (![fileContents writeToFile:outputFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            printf("ERROR: Writing output file failed with error: %s\n", error.localizedDescription.UTF8String);
            exit(EXIT_FAILURE);
        }

        exit(EXIT_SUCCESS);

    }
    return 0;
}