/**
 * Copyright (c) 2014-2018, Plexteq OÜ
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

#import <Foundation/Foundation.h>
#import <libxml/xmlmemory.h>
#import <libxml/parser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>
#import <libxml/tree.h>

@class XmlNode;
@class XmlDocument;

#define XML_ELEMENT_ANY 0
#define XML_ELEMENT_INVALID -1

/**
 * Macroses for C string to NSString conversion and vice-versa
 */
#define nsstr(s) [NSString stringWithUTF8String: (char*) s]
#define cstr(s) (xmlChar*) [s cStringUsingEncoding:NSUTF8StringEncoding]

/**
 * Interface for managing XmlNode objects
 */
@interface XmlNode : NSObject

/**
 * Reference to the document containing the node
 */
@property (strong) XmlDocument* document;

/**
 * Pointer to the node managed by libxml2
 */
@property xmlNodePtr node;

/**
 * Reference to XPath libxml2 object if applicable
 */
@property xmlXPathObjectPtr xpathObject;

/**
 * Creates new node not linked to a document with a given name
 */
-(id)initWithName: (NSString*) name;

/**
 * Constructs XmlNode object with pointer managed by libxml2
 */
-(id)initWithNode: (xmlNodePtr) node;

/**
 * Constructs XmlNode object with pointer managed by libxml2
 * and containing document
 */
-(id)initWithNode: (xmlNodePtr) node andDocument: (XmlDocument*) doc;

/**
 * Looks up and returns child node by provided name or nil if not found
 */
-(XmlNode*)childByName: (NSString*) child;

/**
 * Returns array of child nodes
 */
-(NSArray*)children;

/**
 * Returns array of child nodes of given type
 */
-(NSArray*)childrenWithType: (int) type;

/**
 * Returns dictionary of node attributes (key - attribute name, value - attribute value)
 */
-(NSDictionary*)attributes;

/**
 * Returns first child node or nil
 */
-(XmlNode*)firstChild;

/**
 * Returns text node value
 */
-(NSString*)value;

/**
 * Returns text node name
 */
-(NSString*)name;

/**
 * Returns text node namespace
 */
-(NSString*)namespace;

/**
 * Sets namespace for the node
 */
-(void)setNamespace:(NSString*) ns;

/**
 * Returns text node type
 */
-(int)type;

/**
 * Sets node content
 */
-(void)setValueWithContent: (NSString*) content;

/**
 * Serializes current node into text representation
 */
-(NSString*)serialize;

/**
 * Serializes current node into text representation including namespace
 * definitions from the upper levels
 */
-(NSString*)serializeWithNs;

/**
 * Returns node attribute value by provided name
 */
-(NSString*)attributeValueWithName: (NSString*) name;
-(NSString*)attributeValueWithNamespace: (NSString*) ns andName: (NSString*) name;

/**
 * Removes all children of this node
 */
-(void)removeChildren;

/**
 * Adds child to the current node
 */
-(XmlNode*)appendChildWithName: (NSString*) name;
-(XmlNode*)appendChildWithName: (NSString*) name andTextValue: (NSString*) textValue;

-(XmlNode*)appendChildWithNamespace: (NSString*) ns andName: (NSString*) name;
-(XmlNode*)appendChildWithNamespace: (NSString*) ns andName: (NSString*) name andTextValue: (NSString*) textValue;

/**
 * Adds child to the current node which originates from another document
 */
-(void)appendAndAdoptChild: (XmlNode*) source;

/**
 * Checks whether specified attribute exists on the node
 */
-(BOOL)hasAttribute: (NSString*) name;
-(BOOL)hasAttributeWithNamespace: (NSString*) ns andName: (NSString*) name;

/**
 * Adds attribute to the current node
 */
-(void)setAttributeWithName: (NSString*) name andValue: (NSString*) value;
-(void)setAttributeWithNamespace: (NSString*) ns andName: (NSString*) name andValue: (NSString*) value;

/**
 * Adds multiple attributes at a time
 */
-(void)setAttributes: (NSDictionary*) attributes;

/**
 * Removes attribute from current node
 */
-(void)removeAttributeWithName: (NSString*) name;
-(void)removeAttributeWithNamespace: (NSString*) ns andName: (NSString*) name;

/**
 * Returns parent node
 */
-(XmlNode*)parent;

-(XmlNode*)nextSibling;
-(XmlNode*)prevSibling;

-(void)registerNamespaces: (NSDictionary*) ns;
-(void)registerNamespaceWithPrefix: (NSString*) prefix andUrl: (NSString*) url;
-(void)registerDefaultNamespaceWithUrl: (NSString*) url;

-(NSDictionary*) listNamespaces;

/**
 * Destructor
 */
-(void)dealloc;

@end;

/**
 * Interface for managing XmlDocument objects
 */
@interface XmlDocument : NSObject

/**
 * Pointer to the document managed by libxml2
 */
@property xmlDocPtr document;

/**
 * Map of XML namespaces for tags that needs to be handled by
 * program logic
 */
@property NSDictionary* namespaces;

-(id)init;
-(id)initWithNamespaces: (NSDictionary*) ns;

/**
 * Constructs XmlDocument from provided NSURL
 */
-(id)initWithLocation: (NSURL*) url;

/**
 * Constructs XmlDocument from provided NSData and set of namespaces
 */
-(id)initWithData: (NSData*) xmlData andNamespaces: (NSDictionary*) ns;

/**
 * Constructs XmlDocument from provided NSString
 */
-(id)initWithString: (NSString*) xmlString;

/**
 * Constructs XmlDocument from provided NSString and set of namespaces
 */
-(id)initWithString: (NSString*) xmlString andNamespaces: (NSDictionary*) ns;

/**
 * Serializes current document into text representation
 */
-(NSString*)serialize;

/**
 * Returns root XmlNode for this document
 */
-(XmlNode*) root;

/**
 * Sets XmlNode as root for this document
 */
-(void)setRoot: (XmlNode*) node;

/**
 * Evaluates XPath expression and returns XmlNode for it
 */
-(XmlNode*) xpathWithExpression: (NSString*) expression;

/**
 * Destructor
 */
-(void) dealloc;

@end;