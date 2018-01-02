/**
 * Copyright (c) 2014, Plexteq OÜ
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors
 * may be used to endorse or promote products derived from this software without
 * specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <XCTest/XCTest.h>
//#import <PQXMLParserFramework/PQXMLParser.h>
#import "../PQXMLParser/XmlParser.h"


@interface PQXMLParserTests : XCTestCase
    @property (strong, nonatomic) XmlDocument *xmlDocument;
@end

@implementation PQXMLParserTests

-(void)setUp
{
    [super setUp];
    self.xmlDocument = [[XmlDocument alloc] initWithString: [self loadXmlFile]];
}

-(NSString *)loadXmlFile
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"test1" ofType:@"xml"];
    
    return [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:path]
                                 encoding:NSUTF8StringEncoding];
}

-(void) tearDown {
    self.xmlDocument = nil;
    [super tearDown];
}

/**
 * XmlDocument tests
 */

-(void) testDocumentNotNil {
    XCTAssertNotNil(self.xmlDocument);
}

-(void) testXpathWithExpression {
    XmlNode *node = [self.xmlDocument xpathWithExpression:@"//book[@id='bk112']/title"];
    XCTAssertEqualObjects(@"Visual Studio 7: A Comprehensive Guide", [node value]);
}

-(void) testInexistingXpathWithExpression {
    XCTAssertNil([self.xmlDocument xpathWithExpression:@"//book[@id='bk112z']/title"]);
}

-(void) testInvalidXpath {
    XCTAssertNil([self.xmlDocument xpathWithExpression:@"!123"]);
}

-(void) testRootNodeAccessor {
    XCTAssertEqualObjects(@"catalog", [[[self xmlDocument] root] name]);
}

-(void) testSerialization {
    NSString* sourceXml = @"<?xml version=\"1.0\"?>\n<catalog><book id=\"bk101\"><author>Gambardella, Matthew</author></book></catalog>\n";
    XmlDocument *document = [[XmlDocument alloc] initWithString: sourceXml];
    XCTAssertEqualObjects(sourceXml, [document serialize]);
}

-(void) testMalformedXml {
    NSString* sourceXml = @"<?xml version=\"1.0\"?>\n<catalog>";
    XmlDocument *document = [[XmlDocument alloc] initWithString: sourceXml];
    XCTAssertNil([document root]);
}


/**
 * XmlNode tests
 */

-(void)testChildByName
{
    XmlNode *rootNode = [self.xmlDocument root];
    XmlNode *childNode = [rootNode childByName:@"book"];
    
    XCTAssertEqualObjects(@"book", [childNode name]);
    XCTAssertEqualObjects(@"bk101", [childNode attributeValueWithName:@"id"]);
    XCTAssertEqualObjects(@"Computer", [[childNode childByName:@"genre"] value]);
}

-(void)testInexistingChildByName
{
    XCTAssertNil([[self.xmlDocument root] childByName:@"bookz"]);
}

-(void)testNodeType
{
    XmlNode *rootNode = [self.xmlDocument root];
    int type = [[rootNode childByName:@"book"] type];
    XCTAssertEqual((int)XML_ELEMENT_NODE, type);
}

-(void)testChildren
{
    XmlNode *rootNode = [self.xmlDocument root];
    XCTAssertEqual(12, [[rootNode children] count]);
}

-(void)testFirstChild
{
    XmlNode *rootNode = [self.xmlDocument root],
            *bookNode = [rootNode firstChild],
            *authorNode = [bookNode firstChild];
    
    XCTAssertNotNil(bookNode);
    XCTAssertEqualObjects(@"book", [bookNode name]);
    
    XCTAssertNotNil(authorNode);
    XCTAssertEqualObjects(@"author", [authorNode name]);
    
    XCTAssertNil([authorNode firstChild]);
}


-(void)testWildcardChildren
{
    XmlNode *rootNode = [self.xmlDocument root];
    XCTAssertEqual(25, [[rootNode childrenWithType: XML_ELEMENT_ANY] count]);
}

-(void)testAttributes
{
    XmlNode *rootNode = [self.xmlDocument root],
            *bookNode = [rootNode children][0],
            *authorNode = [bookNode children][0];
    
    NSDictionary *expectedAttributes = [NSDictionary dictionaryWithObject:@"bk101" forKey:@"id"];
    
    XCTAssertNotNil(bookNode);
    XCTAssertEqualObjects(@"book", [bookNode name]);
    XCTAssertEqualObjects(expectedAttributes, [bookNode attributes]);
    
    XCTAssertNotNil(authorNode);
    XCTAssertEqualObjects(@"author", [authorNode name]);
    XCTAssertEqual(0, [[authorNode attributes] count]);
}

-(void)testSetValue
{
    XmlNode *rootNode = [self.xmlDocument root],
            *givenNode = [rootNode children][9],
            *firstChild = [givenNode firstChild];
    
    [firstChild setValueWithContent:@"Think Different"];
    XCTAssertEqualObjects(@"Think Different", [firstChild value]);
}

-(void)testSerializeForNodeContent
{
    XmlNode *rootNode = [self.xmlDocument root],
            *givenNode = [rootNode children][5],
            *firstChild = [givenNode firstChild];
    
    XCTAssertEqualObjects(@"<author>Randall, Cynthia</author>", [firstChild serialize]);
}

-(void)testAttributeValueWithName
{
    XmlNode *rootNode = [self.xmlDocument root],
            *givenNode = [rootNode children][6];
    
    XCTAssertEqualObjects(@"bk107", [givenNode attributeValueWithName:@"id"]);
}

-(void)testRemoveChildren
{
    XmlNode *rootNode = [self.xmlDocument root],
            *givenNode = [rootNode children][7];
    
    XCTAssertEqual(6, [[givenNode children] count]);
    
    [givenNode removeChildren];
    
    XCTAssertEqual(0, [[givenNode children] count]);
    XCTAssertNil([givenNode firstChild]);
}

-(void)testAppendChild
{
    XmlNode *rootNode = [self.xmlDocument root],
            *givenNode = [rootNode children][1],
            *nodeToAppend = [rootNode children][11];
    
    [givenNode removeChildren];
    [givenNode appendChild:nodeToAppend];
    
    XCTAssertEqualObjects(@"Galos, Mike", [[givenNode firstChild] value]);
}

-(void)testHasAttribute
{
    XmlNode *rootNode = [self.xmlDocument root],
            *givenNode = [rootNode children][11];
    
    XCTAssertTrue([givenNode hasAttribute:@"id"]);
    XCTAssertFalse([givenNode hasAttribute:@"zzz"]);
}

- (void)testSetAttributeWithNameAndValue
{
    XmlNode *rootNode = [self.xmlDocument root],
            *givenNode = [rootNode children][5];
    
    [givenNode setAttributeWithName:@"name" andValue:@"Apple1981"];
    XCTAssertEqualObjects(@"Apple1981", [givenNode attributeValueWithName:@"name"]);
}

- (void)testRemoveAttribute
{
    XmlNode *rootNode = [self.xmlDocument root],
            *givenNode = [rootNode children][5];
    
    XCTAssertTrue([givenNode hasAttribute:@"id"]);
    
    [givenNode removeAttributeWithName:@"id"];
    
    XCTAssertFalse([givenNode hasAttribute:@"id"]);
}

- (void)testParentNode
{
    XmlNode *rootNode = [self.xmlDocument root],
            *givenNode = [rootNode children][5];
    
    XCTAssertEqualObjects(@"catalog", [[givenNode parent] name]);
}

- (void)testNextSibling
{
    XmlNode *rootNode = [self.xmlDocument root],
            *givenNode = [rootNode children][9],
            *nextSibling = [givenNode nextSibling];
    
    XCTAssertNotNil(nextSibling);
    XCTAssertEqualObjects(@"bk111", [nextSibling attributeValueWithName:@"id"]);
    
    XCTAssertNotNil([nextSibling nextSibling]);
    XCTAssertEqualObjects(@"bk112", [[nextSibling nextSibling] attributeValueWithName:@"id"]);
    
    XCTAssertNil([[nextSibling nextSibling] nextSibling]);
}


- (void)testPrevSibling
{
    XmlNode *rootNode = [self.xmlDocument root],
            *givenNode = [rootNode children][2],
            *prevSibling = [givenNode prevSibling];
    
    XCTAssertNotNil(prevSibling);
    XCTAssertEqualObjects(@"bk102", [prevSibling attributeValueWithName:@"id"]);
    
    XCTAssertNotNil([prevSibling prevSibling]);
    XCTAssertEqualObjects(@"bk101", [[prevSibling prevSibling] attributeValueWithName:@"id"]);
    
    XCTAssertNil([[prevSibling prevSibling] prevSibling]);
}

@end
