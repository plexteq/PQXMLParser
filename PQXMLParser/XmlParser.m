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

#import "XmlParser.h"

@implementation XmlNode

@synthesize document;
@synthesize xpathObject;

-(id)initWithNode: (xmlNodePtr) node
{
    self = [super init];
    if (self) {
        self->_node = node;
    }
    return self;
}

-(BOOL) isValidNode: (xmlNodePtr) node
{
    if (!self->_node)
        return NO;

    int type = [self typeWithNode:node];
    if (type == XML_ELEMENT_INVALID)
        return NO;
    
    return YES;
}

-(id)initWithNode: (xmlNodePtr) node andDocument: (XmlDocument*) doc
{
    int type = [self typeWithNode:node];

    if (type == XML_ELEMENT_INVALID)
        return nil;
    
    //if ([self typeWithNode:node] != XML_ELEMENT_NODE)
        //return nil;
    
    self = [self initWithNode: node];
    if (self) {
        [self setDocument: doc];
    }
    return self;
}

/**
 * Node location methods
 */

-(XmlNode*)childByName: (NSString*) childName
{
    if (!self->_node)
        return nil;
    
    xmlChar* name = (xmlChar*) [childName cStringUsingEncoding:NSUTF8StringEncoding];
    xmlNodePtr child = self->_node->children;
    
    while (child)
    {
        BOOL isNode = [self typeWithNode:child] == XML_ELEMENT_NODE,
            nodeMatches = xmlStrcasecmp(name, child->name) == 0;
        
        if (isNode && nodeMatches)
            return [[XmlNode alloc] initWithNode:child andDocument:self->document];
        
        child = child->next;
    }
    
    return nil;
}

-(XmlNode*)firstChild
{
    if (!self->_node)
        return nil;
    
    xmlNodePtr child = self->_node->children;
    
    if (child == NULL)
        return nil;
    
    xmlNodePtr next = child->next;
    
    return [[XmlNode alloc] initWithNode:next andDocument:self.document];
}

-(NSArray*)children {
    return [self childrenWithType: XML_ELEMENT_NODE];
}

-(NSArray*)childrenWithType: (int) type
{
    if (!self->_node)
        return nil;
    
    xmlNodePtr node = self->_node->children;
    NSMutableArray* nodes = [[NSMutableArray alloc] init];
    
    while (node)
    {
        BOOL typeMatches = ([self typeWithNode:node] == type),
             wildcardTypeRequested = (type == XML_ELEMENT_ANY);
        
        if (typeMatches || wildcardTypeRequested) {
            [nodes addObject:[[XmlNode alloc] initWithNode:node andDocument:[self document]]];
        }
        
        node = node->next;
    }
    
    return nodes;
}

-(XmlNode*)prevSibling
{
    if (!self->_node)
        return nil;
    
    xmlNode* prevSibling = self->_node->prev;

    while (true)
    {
        if (!prevSibling)
            return nil;
        
        int type = [self typeWithNode:prevSibling];
        
        switch (type) {
            case XML_ELEMENT_INVALID:
                return nil;
            case XML_ELEMENT_NODE:
                return [[XmlNode alloc] initWithNode:prevSibling andDocument:self.document];
            default:
                prevSibling = prevSibling->prev;
                continue;
        }
    }
    
    return nil;
}

-(XmlNode*)nextSibling
{
    if (!self->_node)
        return nil;
    
    xmlNode* nextSibling = self->_node->next;
    
    while (1)
    {
        if (!nextSibling)
            return nil;

        int type = [self typeWithNode:nextSibling];
        
        switch (type) {
            case XML_ELEMENT_INVALID:
                return nil;
            case XML_ELEMENT_NODE:
                return [[XmlNode alloc] initWithNode:nextSibling andDocument:self.document];
            default:
                nextSibling = nextSibling->next;
                continue;
        }
    }
    
    return nil;
}

-(XmlNode*)parent
{
    if (self->_node == NULL || self->_node->parent == NULL)
        return nil;
    
    return [[XmlNode alloc] initWithNode: self->_node->parent andDocument: [self document]];
}

/**
 * Attribute manipulation methods
 */

-(NSDictionary*)attributes
{
    if (!self->_node)
        return @{};
    
    xmlAttr *attribute = self->_node->properties;
    if (attribute == NULL)
        return @{};
    
    NSMutableDictionary* attributes = [[NSMutableDictionary alloc] init];
    
    while (attribute)
    {
        NSString* key = [NSString stringWithUTF8String: (const char*) attribute->name];
        NSString* value = [NSString stringWithUTF8String: (const char*) attribute->children->content];
        [attributes setValue:value forKey:key];
        
        attribute = attribute->next;
    }
    
    return attributes;
}

-(NSString*)attributeValueWithName: (NSString*) name
{
    if (!self->_node)
        return nil;
    
    xmlChar* attrName = (xmlChar*) [name cStringUsingEncoding:NSUTF8StringEncoding];
    
    if (![self hasAttribute:name])
        return nil;
    
    xmlChar* rawValue = xmlGetProp(self->_node, attrName);
    NSString* value = [NSString stringWithUTF8String: (const char*) rawValue];
    xmlFree(rawValue);
    
    return value;
}

-(BOOL)hasAttribute: (NSString*) name
{
    if (!self->_node)
        return nil;
    
    xmlChar* attrName = (xmlChar*) [name cStringUsingEncoding:NSUTF8StringEncoding];
    
    return xmlHasProp(self->_node, attrName) != NULL;
}

-(void)setAttributeWithName: (NSString*) name andValue: (NSString*) value
{
    if (self->_node == NULL)
        return;
    
    if (!name)
        return;
    
    if (!value)
        return;
    
    xmlChar* attrName = (xmlChar*) [name cStringUsingEncoding:NSUTF8StringEncoding];
    xmlChar* attrValue = (xmlChar*) [value cStringUsingEncoding:NSUTF8StringEncoding];
    
    if ([self hasAttribute:name])
        xmlSetProp(self->_node, attrName, attrValue);
    else
        xmlNewProp(self->_node, attrName, attrValue);
}

-(void)removeAttributeWithName: (NSString*) name
{
    if (self->_node == NULL)
        return;
    
    if (!name)
        return;
    
    if (![self hasAttribute:name])
        return;
    
    xmlChar* attrName = (xmlChar*) [name cStringUsingEncoding:NSUTF8StringEncoding];
    xmlUnsetProp(self->_node, attrName);
}

/**
 * Serialization methods
 */

-(NSString*) serialize
{
    NSString* result;
    
    xmlBufferPtr buffer = xmlBufferCreate();
    if (buffer)
    {
        xmlNodeDump(buffer, self->_node->doc, self->_node, 0, 1);
        result = [NSString stringWithUTF8String: (const char*) xmlBufferContent(buffer)];
        xmlBufferFree(buffer);
    }
    
    return result;
}

-(NSString*)serializeWithNs
{
    NSString* result;
    
    // creating temporary node where namespaces will be added
    // in order to not modify existing node and document
    xmlNodePtr tempNode = xmlCopyNode(self->_node, 1);
    
    // iterating to the top of XML hierarchy and adding all specififc namespaces to the node
    XmlNode* shadowNode = self;
    while (shadowNode->_node->name)
    {
        xmlNsPtr* namespaces = xmlGetNsList(shadowNode->_node->doc, shadowNode->_node);
        for (int i = 0 ; namespaces[i] != NULL; ++i)
        {
            if ([self checkNamespaceWithNode:tempNode andNamespace:(namespaces[i])->prefix])
                continue;
            
            xmlNewNs(tempNode, (namespaces[i])->href, (namespaces[i])->prefix);
        }
        
        xmlFree(namespaces);
        
        shadowNode = [shadowNode parent];
    }
    
    // dumping node content
    xmlBufferPtr buffer = xmlBufferCreate();
    if (buffer)
    {
        xmlNodeDump(buffer, self->_node->doc, tempNode, 0, 1);
        result = [NSString stringWithUTF8String: (const char*) xmlBufferContent(buffer)];
        xmlBufferFree(buffer);
    }
    
    // dispose temporary node
    xmlFreeNode(tempNode);
    
    return result;
}

/**
 * Children manipulation
 */

-(void)removeChildren
{
    if (self->_node == NULL)
        return;
    
    xmlNodePtr child = self->_node->children;
    
    if (child == NULL)
        return;
    
    while (child)
    {
        xmlNodePtr next = child->next;
        
        xmlUnlinkNode(child);
        xmlFreeNode(child);
        
        child = next;
    }
}

-(void)appendChild: (XmlNode*) source
{
    xmlNodePtr nodeToInject = xmlDocCopyNode(source->_node, [[self document] document], 1);
    xmlNodePtr injectedNode = xmlAddChildList(self->_node, nodeToInject->children);
    
    if (!injectedNode) {
        xmlFreeNode(injectedNode);
        return;
    }
}

/**
 * Node manipulation
 */

/**
 * Returns node type, one of the following values:
 * XML_ELEMENT_NODE
 * XML_ATTRIBUTE_NODE
 * XML_TEXT_NODE
 * XML_CDATA_SECTION_NODE
 * XML_ENTITY_REF_NODE
 * XML_ENTITY_NODE
 * XML_PI_NODE
 * XML_COMMENT_NODE
 * XML_DOCUMENT_NODE
 * XML_DOCUMENT_TYPE_NODE
 * XML_DOCUMENT_FRAG_NODE
 * XML_NOTATION_NODE
 * XML_HTML_DOCUMENT_NODE
 * XML_DTD_NODE
 * XML_ELEMENT_DECL
 * XML_ATTRIBUTE_DECL
 * XML_ENTITY_DECL
 * XML_NAMESPACE_DECL
 * XML_XINCLUDE_START
 * XML_XINCLUDE_END
 * XML_DOCB_DOCUMENT_NODE
 */
-(int)type {
    return [self typeWithNode: self->_node];
}

-(int)typeWithNode: (xmlNodePtr) nodePtr
{
    if (!nodePtr)
        return XML_ELEMENT_INVALID;
    
    return nodePtr->type;
}

-(NSString*)value
{
    if (!self->_node)
        return nil;
    
    xmlChar* contents = xmlNodeGetContent(self->_node);
    NSString* result = [NSString stringWithUTF8String: (const char*) contents];
    xmlFree(contents);
    
    return result;
}

-(NSString*)name
{
    if (!self->_node)
        return nil;
    
    return [NSString stringWithUTF8String: (const char*) self->_node->name];
}

-(void)setValueWithContent: (NSString*) content
{
    if (!self->_node)
        return;
    
    xmlChar* data = (xmlChar*) [content cStringUsingEncoding:NSUTF8StringEncoding];
    xmlNodeSetContent(self->_node, data);
}

/**
 * Misc
 */

-(BOOL)checkNamespaceWithNode: (xmlNodePtr) node andNamespace: (const xmlChar*) namespace
{
    if (!node)
        return false;
    
    if (!namespace)
        return false;
    
    if (node->ns == NULL)
        return false;
    
    xmlNs* namespaces = node->ns;
    
    while (namespaces && namespaces->prefix)
    {
        if (!strcmp((const char*) namespace, (const char*) namespaces->prefix))
            return true;
        
        namespaces = namespaces->next;
    }
    
    return false;
}

-(void)dealloc {
    if ([self xpathObject])
        xmlXPathFreeObject(xpathObject);
}

@end;

/**
 * XmlDocument
 */

@implementation XmlDocument

@synthesize document;
@synthesize namespaces;

-(id)initWithString: (NSString*) xmlString
{
    self = [super init];
    if (self) {
        [self setDocument: xmlParseDoc( (xmlChar*) [xmlString cStringUsingEncoding:NSUTF8StringEncoding])];
    }
    return self;
}

-(id)initWithData: (NSData*) xmlData andNamespaces: (NSDictionary*) ns
{
    self = [super init];
    if (self) {
        [self setNamespaces: ns];
        NSString* data = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
        [self setDocument: xmlParseDoc( (xmlChar*) [data cStringUsingEncoding:NSUTF8StringEncoding])];
    }
    return self;
}

-(id)initWithString: (NSString*) xmlString andNamespaces: (NSDictionary*) ns
{
    self = [super init];
    if (self) {
        [self setNamespaces: ns];
        [self setDocument: xmlParseDoc((xmlChar*)[xmlString cStringUsingEncoding:NSUTF8StringEncoding])];
    }
    return self;
}

-(NSString*)serialize
{
    int* length = NULL;
    xmlChar* xml;
    NSString* result;
    
    xmlDocDumpMemory([self document], &xml, length);
    
    if (xml) {
        result = [NSString stringWithCString: xml encoding:NSUTF8StringEncoding];
        xmlFree(xml);
    }
    
    return result;
}

-(XmlNode*)xpathWithExpression: (NSString*) expression
{
    xmlXPathContextPtr context;
    xmlXPathObjectPtr result;
    
    XmlNode* resultNode;
    
    context = xmlXPathNewContext([self document]);
    if (context == NULL)
        return nil;
    
    // registering namespaces
    for (NSString* key in [self namespaces]) {
        NSString* value = [[self namespaces] valueForKey: key];
        xmlXPathRegisterNs(context, (xmlChar*) [key cStringUsingEncoding: NSUTF8StringEncoding],
                           (const xmlChar*) [value cStringUsingEncoding: NSUTF8StringEncoding]);
    }
    
    result = xmlXPathEvalExpression((xmlChar*)[expression cStringUsingEncoding: NSUTF8StringEncoding], context);
    
    if (result == NULL) {
        xmlXPathFreeContext(context);
        return nil;
    }
    
    if (xmlXPathNodeSetIsEmpty(result->nodesetval)) {
        xmlXPathFreeObject(result);
        xmlXPathFreeContext(context);
        return nil;
    }
    
    resultNode = [[XmlNode alloc] initWithNode: result->nodesetval->nodeTab[0] andDocument: self];
    [resultNode setXpathObject: result];
    
    xmlXPathFreeContext(context);
    
    return resultNode;
}

-(XmlNode*)root
{
    if ([self document] == nil)
        return nil;
    
    return [[XmlNode alloc] initWithNode: xmlDocGetRootElement([self document])];
}

-(void)dealloc {
    xmlFreeDoc([self document]);
}


@end