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

#import "XmlParser.h"

@implementation XmlNode

@synthesize document;
@synthesize xpathObject;

-(id)initWithName: (NSString*) name {
    return [self initWithNode:xmlNewNode(NULL, cstr(name))];
}

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

    if ([self typeWithNode:node] == XML_ELEMENT_INVALID)
        return NO;
    
    return YES;
}

-(id)initWithNode: (xmlNodePtr) node andDocument: (XmlDocument*) doc
{
    if ([self isValidNode:[self node]])
        return nil;
    
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
    
    xmlNodePtr child = self->_node->children;
    
    while (child)
    {
        BOOL isNode = [self typeWithNode:child] == XML_ELEMENT_NODE,
        nodeMatches = xmlStrcasecmp(cstr(childName), child->name) == 0;
        
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
    
    //xmlNodePtr next = child->next;
    
    return [[XmlNode alloc] initWithNode:child andDocument:self.document];
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
        [attributes setValue:nsstr(attribute->children->content)
                      forKey:nsstr(attribute->name)];
        
        attribute = attribute->next;
    }
    
    return attributes;
}

-(NSString*)attributeValueWithName: (NSString*) name
{
    if (!self->_node)
        return nil;
    
    if (!name)
        return nil;
    
    if (![self hasAttribute:name])
        return nil;
    
    xmlChar* rawValue = xmlGetProp(self->_node, cstr(name));
    NSString* value = nsstr(rawValue);
    xmlFree(rawValue);
    
    return value;
}

-(NSString*)attributeValueWithNamespace: (NSString*) ns andName: (NSString*) name
{
    if (!self->_node)
        return nil;
    
    if (![self hasAttributeWithNamespace:ns andName:name])
        return nil;
    
    xmlNs* srcNs = [self namespaceByPrefix: cstr(ns)];
    
    xmlChar* rawValue = xmlGetNsProp(self->_node, cstr(name), srcNs->href);
    NSString* value = nsstr(rawValue);
    xmlFree(rawValue);
    
    return value;
}

-(BOOL)hasAttribute: (NSString*) name
{
    if (!self->_node)
        return NO;
    
    if (!name)
        return NO;
    
    return xmlHasProp(self->_node, cstr(name)) != NULL;
}

-(BOOL)hasAttributeWithNamespace: (NSString*) ns andName: (NSString*) name
{
    if (!self->_node)
        return NO;
    
    if (!ns || !name)
        return NO;
    
    return xmlHasNsProp(self->_node, cstr(name), [self namespaceByPrefix:cstr(ns)]->href) != NULL;
}
    
-(void)setAttributes: (NSDictionary*) attributes
{
    [attributes enumerateKeysAndObjectsUsingBlock:^(NSString* name, NSString*  value, BOOL * stop) {
        [self setAttributeWithName:name andValue:value];
    }];
}

-(void)setAttributeWithName: (NSString*) name andValue: (NSString*) value
{
    if (self->_node == NULL)
        return;
    
    if (!name || !value)
        return;
    
    if ([self hasAttribute:name])
        xmlSetProp(self->_node, cstr(name), cstr(value));
    else
        xmlNewProp(self->_node, cstr(name), cstr(value));
}

-(void)setAttributeWithNamespace: (NSString*) namespace andName: (NSString*) name andValue: (NSString*) value
{
    if (self->_node == NULL)
        return;
    
    if (!namespace || !name || !value)
        return;
    
    if ([self hasAttributeWithNamespace:namespace andName:name])
        xmlSetNsProp(self->_node, [self namespaceByPrefix:cstr(namespace)], cstr(name), cstr(value));
    else
        xmlNewNsProp(self->_node, [self namespaceByPrefix:cstr(namespace)], cstr(name), cstr(value));
}

-(void)removeAttributeWithName: (NSString*) name
{
    if (self->_node == NULL)
        return;
    
    if (!name)
        return;
    
    if (![self hasAttribute:name])
        return;
    
    xmlUnsetProp(self->_node, cstr(name));
}

-(void)removeAttributeWithNamespace: (NSString*) ns andName: (NSString*) name
{
    if (self->_node == NULL)
        return;
    
    if (!name || !ns)
        return;
    
    if (![self hasAttributeWithNamespace:ns andName:name])
        return;
    
    xmlUnsetNsProp(self->_node, [self namespaceByPrefix:cstr(ns)], cstr(name));
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
        result = nsstr(xmlBufferContent(buffer));
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
        result = nsstr(xmlBufferContent(buffer));
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

-(void)appendAndAdoptChild: (XmlNode*) source
{
    xmlNodePtr nodeToInject = xmlDocCopyNode(source->_node, [[self document] document], 1);
    xmlNodePtr injectedNode = xmlAddChild(self->_node, nodeToInject->children);
    
    if (!injectedNode) {
        xmlFreeNode(injectedNode);
        return;
    }
}

-(XmlNode*)appendChildWithName: (NSString*) name
{
    xmlNodePtr newNode = xmlNewChild([self node], NULL, cstr(name), NULL);
    return [[XmlNode alloc] initWithNode:newNode];
}

-(XmlNode*)appendChildAsNextSiblingWithName: (NSString*) name
{
    XmlNode *newNode = [self appendChildWithName:name];
    xmlAddNextSibling([self node], [newNode node]);
    return newNode;
}

-(XmlNode*)appendChildAsPrevSiblingWithName: (NSString*) name
{
    XmlNode *newNode = [self appendChildWithName:name];
    xmlAddPrevSibling([self node], [newNode node]);
    return newNode;
}

-(XmlNode*)appendChildWithNamespace: (NSString*) ns andName: (NSString*) name
{
    XmlNode* newNode = [self appendChildWithName:name];
    [newNode setNamespace:ns];
    
    return newNode;
}

-(XmlNode*)appendChildAsNextSiblingWithNamespace: (NSString*) ns andName: (NSString*) name
{
    XmlNode *newNode = [self appendChildWithNamespace:ns andName:name];
    xmlAddNextSibling([self node], [newNode node]);
    return newNode;
}

-(XmlNode*)appendChildAsPrevSiblingWithNamespace: (NSString*) ns andName: (NSString*) name
{
    XmlNode *newNode = [self appendChildWithNamespace:ns andName:name];
    xmlAddPrevSibling([self node], [newNode node]);
    return newNode;
}


-(XmlNode*)appendChildWithName: (NSString*) name andTextValue: (NSString*) textValue
{
    XmlNode* newNode = [self appendChildWithName:name];
    [newNode setValueWithContent: textValue];
    
    return newNode;
}
    
-(XmlNode*)appendChildAsNextSiblingWithName: (NSString*) name andTextValue: (NSString*) textValue
{
    XmlNode *newNode = [self appendChildWithName:name andTextValue:textValue];
    xmlAddNextSibling([self node], [newNode node]);
    return newNode;
}

-(XmlNode*)appendChildAsPrevSiblingWithName: (NSString*) name andTextValue: (NSString*) textValue
{
    XmlNode *newNode = [self appendChildWithName:name andTextValue:textValue];
    xmlAddPrevSibling([self node], [newNode node]);
    return newNode;
}

-(XmlNode*)appendChildWithNamespace: (NSString*) ns andName: (NSString*) name andTextValue: (NSString*) textValue
{
    XmlNode* newNode = [self appendChildWithName:name andTextValue:textValue];
    xmlSetNs([newNode node], [self namespaceByPrefix:cstr(ns)]);
    
    return newNode;
}

-(XmlNode*)appendChildAsNextSiblingWithNamespace: (NSString*) ns andName: (NSString*) name andTextValue: (NSString*) textValue
{
    XmlNode *newNode = [self appendChildWithNamespace:ns andName:name andTextValue:textValue];
    xmlAddNextSibling([self node], [newNode node]);
    return newNode;
}

-(XmlNode*)appendChildAsPrevSiblingWithNamespace: (NSString*) ns andName: (NSString*) name andTextValue: (NSString*) textValue
{
    XmlNode *newNode = [self appendChildWithNamespace:ns andName:name andTextValue:textValue];
    xmlAddPrevSibling([self node], [newNode node]);
    return newNode;
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
    NSString* result = nsstr(contents);
    xmlFree(contents);
    
    return result;
}

-(NSString*)name
{
    if (!self->_node)
        return nil;
    
    return nsstr(self->_node->name);
}

-(NSString*)namespace
{
    if (![self node])
        return nil;
    
    if (![self node]->ns)
        return nil;
    
    return nsstr(self->_node->ns->prefix);
}

-(void)setNamespace:(NSString*) ns
{
    if (![self node])
        return;
    
    xmlSetNs([self node], [self namespaceByPrefix:cstr(ns)]);
}

-(void)setValueWithContent: (NSString*) content
{
    if (!self->_node)
        return;
    
    xmlNodeSetContent(self->_node, cstr(content));
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

-(void)registerNamespaces: (NSDictionary*) ns
{
    if (!ns)
        return;
    
    if (!self->_node)
        return;
    
    [ns enumerateKeysAndObjectsUsingBlock:^(NSString* k, NSString* v, BOOL* stop) {
        [self registerNamespaceWithPrefix:k andUrl:v];
    }];
}

-(void)registerDefaultNamespaceWithUrl: (NSString*) url
{
    [self registerNamespaceWithPrefix:nil andUrl:url];
}

-(void)registerNamespaceWithPrefix: (NSString*) prefix andUrl: (NSString*) url
{
    if (!self->_node)
        return;
    
    if (!url)
        return;

    // if prefix is NULL it will be handled as default
    xmlNewNs([self node], cstr(url), prefix ? cstr(prefix) : NULL);
}

-(void)dealloc
{
    if ([self xpathObject])
        xmlXPathFreeObject(xpathObject);
}

-(NSDictionary*) listNamespaces
{
    xmlNs **nsList = xmlGetNsList([[self document] document], [self node]);
    
    if (!nsList)
        return @{};
    
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    
    for (int i = 0; nsList[i] != NULL ; i++)
    {
        if (nsList[i]->prefix == NULL)
            continue;
        
        [result setValue: nsstr(nsList[i]->href)
                  forKey: nsstr(nsList[i]->prefix)];
    }
    
    xmlFree(nsList);
    
    return result;
}

-(xmlNs*) namespaceByPrefix: (xmlChar*) prefix
{
    xmlNs **nsList = xmlGetNsList([[self document] document], [self node]);
    xmlNs *result = NULL;
    
    if (!nsList)
        return NULL;
    
    for (int i = 0; nsList[i] != NULL ; i++)
    {
        if (nsList[i]->prefix == NULL)
            continue;
        
        if (!xmlStrcmp(prefix, nsList[i]->prefix))
            result = nsList[i];
    }
    
    xmlFree(nsList);
    
    return result;
}

@end;

/**
 * XmlDocument
 */

@implementation XmlDocument

@synthesize document;
@synthesize namespaces;

-(id)init
{
    self = [super init];
    if (self) {
        [self setDocument: xmlNewDoc(BAD_CAST "1.0")];
        char* encoding = calloc(6,1);
        strcpy(encoding, "UTF-8");
        [self document]->encoding = encoding;
        [self document]->standalone = 1;
    }
    return self;
}

-(id)initWithNamespaces: (NSDictionary*) ns
{
    if (self = [self init]) {
        [self setNamespaces:ns];
    }
    return self;
}

-(id)initWithString: (NSString*) xmlString
{
    self = [super init];
    if (self) {
        [self setDocument: xmlParseDoc(cstr(xmlString))];
    }
    return self;
}

-(id)initWithLocation: (NSURL*) url
{
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:[url path]];
    return [self initWithData:data andNamespaces:nil];
}

-(id)initWithData: (NSData*) xmlData andNamespaces: (NSDictionary*) ns
{
    self = [super init];
    if (self) {
        [self setNamespaces: ns];
        NSString* data = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
        [self setDocument: xmlParseDoc(cstr(data))];
    }
    return self;
}

-(id)initWithString: (NSString*) xmlString andNamespaces: (NSDictionary*) ns
{
    self = [super init];
    if (self) {
        [self setNamespaces: ns];
        [self setDocument: xmlParseDoc(cstr(xmlString))];
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
        result = nsstr(xml);
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
    
    NSMutableDictionary *xpathNamespaces = [[NSMutableDictionary alloc] init];
    
    if ([self namespaces])
        [xpathNamespaces addEntriesFromDictionary:[self namespaces]];
    
    [xpathNamespaces addEntriesFromDictionary:[[self root] listNamespaces]];
    
    // registering namespaces
    for (NSString* key in xpathNamespaces) {
        NSString* value = [xpathNamespaces valueForKey: key];
        xmlXPathRegisterNs(context, cstr(key), cstr(value));
    }
    
    result = xmlXPathEvalExpression(cstr(expression), context);
    
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

-(void)setRoot: (XmlNode*) node
{
    if ([self document] == nil)
        return;
    
    if (!node || ![node node])
        return;
    
    xmlDocSetRootElement([self document], [node node]);
}

-(void)dealloc {
    xmlFreeDoc([self document]);
}


@end