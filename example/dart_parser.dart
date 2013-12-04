import 'package:syntax/parser.dart';
import './dart_lang.dart';

class VariableDeclaration extends AstNode {
  VariableDeclaration(asts){
    var tokens = asts.reduce((r,_) => r..tokens.addAll(_.tokens)).tokens;
    for(final token in tokens){
      if(token is Identifier){
        children.add(new IdentifierNode()..tokens.add(token));
      }
    }
  }
}
class IdentifierNode extends AstNode {}

variableDeclaration() =>
    px([ declaredIdentifier, zeroOrMore(and([ ',', identifier ]))]) <=
        (ast) => new VariableDeclaration(ast);

declaredIdentifier() =>
    px([
      metadata,
      finalConstVarOrType,
      identifier
    ]);

identifier() => new Identifier();
finalConstVarOrType() =>
    or([
      px([ 'final', optional(type) ]),
      px([ 'const', optional(type) ]),
      varOrType
    ]);

varOrType() =>
    or([
      'var',
      type
    ]);

type() => px([ typeName, optional(typeArguments) ]);
typeName() => qualified;

qualified() => px([ identifier, optional(and([ '.', identifier ])) ]);
typeArguments() => px([ '<', typeList, '>' ]);
typeList() => px([ type, zeroOrMore( and([ ',', type ])) ]);

initializedVariableDeclaration() =>
    px([ declaredIdentifier,
         optional(and([ '=', expression])),
         zeroOrMore(and([ ',', initializedIdentifier]))
      ]);

initializedIdentifier() => px([ identifier,
                                optional(and([ '=', expression ]))]);

initializedIdentifierList() =>
    px([ initializedIdentifier,
         zeroOrMore( and([ ',', initializedIdentifier ]))
      ]);



/// Functions
functionSignature() =>
     px([
          metadata,
          optional(returnType),
          identifier,
          formalParameterList ]);

returnType() => or([ 'void', type]);

functionBody() =>
    or([ and([
              '=>',
              expression,
              ';'
           ]),
         block
         ]);

block() =>
        px([ '{',
             statements,
             '}'
          ]);

/// Formal Parameters
formalParameterList() =>
    or([
         and([ '(', ')' ]),
         and([ '(',
               normalFormalParameters,
               optional(and([ ',', optionalFormalParameters])),
               ')' ]),
         and([ '(', optionalFormalParameters, ')' ])
      ]);

normalFormalParameters() =>
    px([
         normalFormalParameter,
         zeroOrMore(and([ ',', normalFormalParameter ]))
      ]);

optionalFormalParameters() =>
    or([
         optionalPositionalFormalParameters,
         namedFormalParameters
      ]);

optionalPositionalFormalParameters() =>
    px([
         '[',
         defaultFormalParameter,
         zeroOrMore( and([ ',', defaultFormalParameter ])),
         ']'
      ]);

namedFormalParameters() =>
    px([
         '{',
         defaultNamedParameter,
         zeroOrMore(and([ ',', defaultNamedParameter ])),
         '}'
      ]);


/// Required Formals
normalFormalParameter() =>
    or([
         functionSignature,
         fieldFormalParameter,
         simpleFormalParameter
      ]);

simpleFormalParameter() =>
    or([
         declaredIdentifier,
         and([ metadata, identifier ])
      ]);

fieldFormalParameter() =>
    px([
         metadata,
         optional(finalConstVarOrType),
         'this',
         '.',
         identifier,
         optional(formalParameterList)
      ]);


/// Optional Formals
defaultFormalParameter() =>
    px([
         normalFormalParameter,
         optional(and([ '=', expression ]))
      ]);

defaultNamedParameter() =>
    px([ normalFormalParameter,
         optional(and([ ':', expression ]))
      ]);

/// Classes
classDefinition() =>
    or([
        and([
              metadata,
              optional('abstract'),
              'class',
              identifier,
              optional(typeParameters),
              optional(and([ superclass, optional(mixins) ])),
              optional(interfaces),
              '{',
              zeroOrMore(and([ metadata, classMemberDefinition ])),
              '}' ]),
        and([
              metadata,
              optional('abstract'),
              'class',
              mixinApplicationClass ])
     ]);

mixins() => px([ 'with', typeList ]);

classMemberDefinition() =>
    or([
         and([ declaration, ';' ]),
         and([ methodSignature, functionBody ])
      ]);

methodSignature() =>
    or([
         and([ constructorSignature,  optional(initializers) ]),
         factoryConstructorSignature,
         and([ optional('static'), functionSignature ]),
         and([ optional('static'), getterSignature ]),
         and([ optional('static'), setterSignature ]),
         operatorSignature
     ]);

declaration() =>
    or([
         and([ constantConstructorSignature,
               optional(or([ redirection, initializers ])) ]),
         and([ constructorSignature,
               optional(or([ redirection, initializers ])) ]),
         and([ 'external', constantConstructorSignature ]),
         and([ 'external', constructorSignature ]),
         and([ 'external', factoryConstructorSignature ]),
         and([ optional(and([ 'external', optional('static') ])),
               getterSignature ]),
         and([ optional(and([ 'external', optional('static') ])),
               setterSignature ]),
         and([ optional('external'), operatorSignature ]),
         and([ optional(and([ 'external', optional('static') ])),
               functionSignature ]),
         getterSignature,
         setterSignature,
         operatorSignature,
         functionSignature,
         and([ 'static',
               or([ 'final', 'const']),
               optional(type),
               staticFinalDeclarationList
            ]),
         and([ 'const', optional(type), staticFinalDeclarationList ]),
         and([ 'final', optional(type), initializedIdentifierList ]),
         and([ 'static',
               or([ 'var', type ]),
               initializedIdentifierList ])
      ]);

staticFinalDeclarationList() =>
    px([ ':',
         staticFinalDeclaration,
         zeroOrMore(and([ ',', staticFinalDeclaration ]))
      ]);

staticFinalDeclaration() =>
    px([ identifier, '=', expression ]);

/// Operators
operatorSignature() =>
    px([
         optional(returnType),
         'operator',
         operator,
         formalParameterList
       ]);

operator() =>
    or([ '~',
         binaryOperator,
         and([ '[', ']' ]),
         and([ '[', ']', '=' ])
    ]);

binaryOperator() =>
    or([
         multiplicativeOperator,
         additiveOperator,
         shiftOperator,
         relationalOperator,
         '==',
         bitwiseOperator
      ]);

/// Generative Constructors
constructorSignature() =>
    px([ identifier, optional(and(['.', identifier ])), formalParameterList ]);

/// Redirecting Constructors
redirection() =>
    px([ ':', 'this', optional(and([ '.', identifier ])), arguments ]);

/// Initializer Lists
initializers() =>
    px([ ':',
         superCallOrFieldInitializer,
         zeroOrMore(and([ ',', superCallOrFieldInitializer ]))
      ]);

superCallOrFieldInitializer() =>
    or([
         and([ 'super', arguments ]),
         and([ 'super', '.', identifier, arguments ]),
         fieldInitializer
      ]);

fieldInitializer() =>
    px([
         optional(and([ 'this', '.'])),
         identifier,
         '=',
         conditionalExpression,
         zeroOrMore(cascadeSection)
      ]);


/// Factories
factoryConstructorSignature() =>
    px([ 'factory',
         identifier,
         optional(and([ '.', identifier])),
         formalParameterList
      ]);

/// Redirecting Factory Constructors
redirectingFactoryConstructorSignature() =>
    px([
         optional('const'),
         'factory',
         identifier,
         optional(and([ '.', identifier ])),
         formalParameterList,
         '=',
         'type',
         optional(and([ '.', identifier ]))
      ]);

/// Constant Constructors
constantConstructorSignature() =>
    px([ 'const', qualified, formalParameterList ]);

/// Superclasses
superclass() => px([ 'extends', type ]);

/// Superinterfaces
interfaces() => px([ 'implements', typeList ]);

/// Mixin Application
mixinApplicationClass() =>
    px([ identifier,
         optional(typeParameters),
         '=',
         mixinApplication,
         ';'
      ]);

mixinApplication() =>
    px([ type, mixins,  optional(interfaces)]);

/// Generics
typeParameter() =>
    px([ metadata, identifier, optional(and([ 'extends', type])) ]);

typeParameters() =>
    px([ '<', typeParameter,
         zeroOrMore(and([ ',', typeParameter ])),
         '>'
      ]);

/// Metadata
metadata() =>
    zeroOrMore(and([
                     '@',
                     qualified,
                     optional(and([ '.', identifier])),
                     optional(arguments)
                   ]));

/// Expressions
expression() =>
    or([
         and([ assignableExpression, assignmentOperator, expression ]),
         and([ conditionalExpression, zeroOrMore(cascadeSection) ]),
         throwExpression
      ]);

expressionWithoutCascade() =>
    or([
        and([ assignableExpression, assignmentOperator, expressionWithoutCascade ]),
        conditionalExpression,
        throwExpressionWithoutCascade
      ]);

expressionList() =>
    and([ expression, zeroOrMore(and([ ',', expression])) ]);


primary() =>
    or([
        thisExpression,
        and([ 'super', assignableSelector ]),
        functionExpression,
        literal,
        identifier,
        newExpression,
        constObjectExpression,
        and([ '(', expression, ')' ])
      ]);

/// Literals
literal() =>
    or([
         nullLiteral,
         booleanLiteral,
         numericLiteral,
         stringLiteral,
         symbolLiteral,
         mapLiteral,
         listLiteral
      ]);

nullLiteral() => px([ 'null' ]);
numericLiteral() => new Number();
booleanLiteral() => or([ 'true', 'false' ]);
/// Strings
stringLiteral() =>
    oneOrMore(and([new StringStart(),
                   zeroOrMore(or([ new StringPart(),
                                   and([ new StringInterpolationStart(),
                                         new StringInterpolation()
                                      ]),
                                ])),
                   new StringEnd()
              ]));
//multilineString() => null;
//singleLineString() => null;

/// Symbols
symbolLiteral() =>
    px(['#',
        or([ operator,
             and([ identifier, zeroOrMore(and([ '.', identifier]))])
           ])
      ]);

/// Lists
listLiteral() =>
        px([
             optional('const'),
             optional(typeArguments),
             '[',
             optional(and([ expressionList, optional(',')])),
             ']'
          ]);

/// Maps
mapLiteral() =>
        px([
             optional('const'),
             optional(typeArguments),
             '{',
             optional(and([ mapLiteralEntry,
                            zeroOrMore(and([ ',', mapLiteralEntry ])),
                            optional(',')
                          ])),
             '}'
           ]);

mapLiteralEntry() =>
       px([ expression, ':', expression ]);

/// Throw
throwExpression() =>
        px([ 'throw', expression ]);

throwExpressionWithoutCascade() =>
        px([ 'throw', expressionWithoutCascade ]);

/// Function Expressions
functionExpression() =>
    px([ formalParameterList, functionExpressionBody ]);

functionExpressionBody() =>
    or([
         and([ '=>', expression ]),
         block
      ]);

/// This
thisExpression() => 'this';

/// New
newExpression() =>
        px([ 'new', type, optional(and([ '.', identifier ])), arguments ]);

/// Const
constObjectExpression() =>
    px([ 'const', type, optional(and([ '.', identifier ])), arguments ]);

/// Actual Argument List Evaluation
arguments() =>
    px([ '(', optional(argumentList), ')' ]);

argumentList() =>
    or([
         and([ namedArgument,  zeroOrMore(and([ ',', namedArgument ])) ]),
         and([ expressionList, zeroOrMore(and([ ',', namedArgument ])) ])
      ]);

namedArgument() => px([ label, expression ]);

/// Cascaded Invocations
cascadeSection() =>
    px([
         '..',
         and([ cascadeSelector, zeroOrMore(arguments) ]),
         zeroOrMore(and([ assignableSelector, zeroOrMore(arguments) ])),
         optional(and([ assignmentOperator, expressionWithoutCascade ]))
      ]);

cascadeSelector() =>
    or([
        and([ '[', expression, ']' ]),
        identifier
      ]);

/// Assignment
assignmentOperator() =>
    or([
        '=',
        compoundAssignmentOperator
      ]);

compoundAssignmentOperator() =>
    or([
        '*=',
        '/=',
        '~/=',
        '%=',
        '+=',
        '-=',
        '<<=',
        '>>=',
        '&=',
        '^=',
        '|='
      ]);

/// Conditional
conditionalExpression() =>
    px([
         logicalOrExpression,
         optional(and([ '?',
                        expressionWithoutCascade,
                        ':',
                        expressionWithoutCascade
                      ]))
      ]);

/// Logical Boolean Expressions
logicalOrExpression() =>
    px([
         logicalAndExpression,
         zeroOrMore(and([ '||', logicalAndExpression ]))
      ]);

logicalAndExpression() =>
    px([
         equalityExpression,
         zeroOrMore(and([ '&&', equalityExpression ]))
      ]);

/// Equality
equalityExpression() =>
    or([
         and([ relationalExpression,
               optional(and([ equalityOperator, relationalExpression ]))
            ]),
         and([ 'super', equalityOperator, relationalExpression ])
       ]);

equalityOperator() =>
    or([
         '==',
         '!='
      ]);

/// Relational Expressions
relationalExpression() =>
    or([
        and([ bitwiseOrExpression,
              optional(or([ typeTest,
                            typeCast,
                            and([ relationalOperator, bitwiseOrExpression ])
                         ])),
           ]),
        and([ 'super', relationalOperator, bitwiseOrExpression ])
      ]);

relationalOperator() =>
   or([
         '>=',
         '>',
         '<=',
         '<',
    ]);

/// Bitwise Expressions
bitwiseOrExpression() =>
    or([
         and([ bitwiseXorExpression,
               zeroOrMore(and([ '|', bitwiseXorExpression ]))
            ]),
         and([ 'super', oneOrMore(and(['|', bitwiseXorExpression ])) ])
      ]);

bitwiseXorExpression() =>
    or([
        and([ bitwiseAndExpression,
              zeroOrMore(and(['^', bitwiseAndExpression ]))
           ]),
        and([ 'super', oneOrMore(and([ '^', bitwiseAndExpression ])) ])
      ]);

bitwiseAndExpression() =>
    or([
        and([ shiftExpression, zeroOrMore(and([ '&', shiftExpression ])) ]),
        and([ 'super', oneOrMore(and([ '&', shiftExpression ])) ])
      ]);

bitwiseOperator() =>
    or([
         '&',
         '^',
         '|'
      ]);

/// Shift
shiftExpression() =>
    or([
         and([ additiveExpression,
               zeroOrMore(and([ shiftOperator, additiveExpression ]))
            ]),
         and([ 'super', oneOrMore(and([ shiftOperator, additiveExpression ])) ])
      ]);

shiftOperator() =>
    or([
         '<<',
         '>>'
      ]);

/// Additive Expressions
additiveExpression() =>
    or([
         and([ multiplicativeExpression,
               zeroOrMore(and([ additiveOperator, multiplicativeExpression ]))
            ]),
         and([ 'super',
               oneOrMore(and([ additiveOperator, multiplicativeExpression ])) ])
      ]);

additiveOperator() =>
    or([
         '+',
         '-'
      ]);

/// Multiplicative Expressions
multiplicativeExpression() =>
    or([
         and([ unaryExpression,
               zeroOrMore(and([ multiplicativeOperator, unaryExpression ]))
            ]),
         and([ 'super',
               oneOrMore(and([ multiplicativeOperator, unaryExpression ]))
            ])
      ]);

multiplicativeOperator() =>
    or([
         '*',
         '/',
         '%',
         '~/'
      ]);

/// Unary Expressions
unaryExpression() =>
    or([
        and([ prefixOperator, unaryExpression ]),
        postfixExpression,
        and([ prefixOperator, 'super' ]),
        and([ incrementOperator, assignableExpression ])
      ]);

prefixOperator() =>
    or([
         '-',
         unaryOperator
      ]);

unaryOperator() =>
    or([
         '!',
         '~'
      ]);

/// Postfix Expressions
postfixExpression() =>
    or([
        and([ assignableExpression, postfixOperator ]),
        and([ primary, zeroOrMore(selector) ])
      ]);

postfixOperator() => incrementOperator;

selector() =>
    or([
         assignableSelector,
         arguments
      ]);

incrementOperator() =>
    or([
         '++',
         '--'
      ]);

/// Assignable Expressions
assignableExpression() =>
    or([
         and([ primary, oneOrMore(and([ zeroOrMore(arguments),
                                        assignableSelector]))
            ]),
         and([ 'super', assignableSelector ]),
         identifier
      ]);

assignableSelector() =>
    or([
         and([ '[', expression, ']' ]),
         and([ '.', identifier ])
      ]);


/// Type Test
typeTest() => px([ isOperator, type ]);
isOperator() => px([ 'is', optional('!') ]);

/// Type Cast
typeCast() => px([ asOperator, type ]);
asOperator() => 'as';

/// Statements
statements() => zeroOrMore(statement);
statement() =>
    px([ zeroOrMore(label), nonLabelledStatement ]);

nonLabelledStatement() =>
    or([
        block,
        and([ localVariableDeclaration, ';' ]),
        forStatement,
        whileStatement,
        doStatement,
        switchStatement,
        ifStatement,
        rethrowStatement,
        tryStatement,
        breakStatement,
        continueStatement,
        returnStatement,
        expressionStatement,
        assertStatement,
        localFunctionDeclaration,
      ]);

/// Expression Statements
expressionStatement() => px([ optional(expression), ';' ]);

/// Local Variable Declaration
localVariableDeclaration() => px([ initializedVariableDeclaration, ';' ]);

/// Local Function Declaration
localFunctionDeclaration() => px([ functionSignature, functionBody ]);

ifStatement() =>
    px([ 'if', '(', expression, ')', statement,
         optional(and([ 'else', statement ]))
      ]);

forStatement() =>
    px([ 'for', '(', forLoopParts, ')', statement ]);

forLoopParts() =>
    or([
        and([ forInitializerStatement, optional(expression), ';',
              optional(expressionList)
           ]),
        and([ declaredIdentifier, 'in', expression ]),
        and([ identifier, 'in', expression ])
      ]);

forInitializerStatement() =>
    or([
        and([ localVariableDeclaration, ';' ]),
        and([ optional(expression), ';' ])
      ]);

/// While
whileStatement() =>
    px([ 'while', '(', expression, ')', statement ]);

/// Do
doStatement() =>
    px([ 'do', statement, 'while', '(', expression, ')', ';' ]);

/// Switch
switchStatement() =>
    px([ 'switch', '(', expression, ')', '{',
         zeroOrMore(switchCase),
         optional(defaultCase), '}'
      ]);

switchCase() =>
    px([ zeroOrMore(label), 'case', expression, ':', statements ]);

defaultCase() =>
    px([ zeroOrMore(label), 'default', ':', statements ]);

/// Rethrow
rethrowStatement() => 'rethrow';

/// Try
tryStatement() =>
    px([
        'try',
        block,
        or([
             and([ oneOrMore(onPart), optional(finallyPart) ]),
             finallyPart
          ])
      ]);

onPart() =>
    or([
         and([ catchPart, block ]),
         and([ 'on', type, optional(catchPart), block ])
      ]);

catchPart() =>
    px([ 'catch', '(', identifier, optional(and([ ',', identifier ])), ')' ]);

finallyPart() =>
    px([ 'finally', block ]);

/// Return
returnStatement() =>
    px([ 'return', optional(expression), ';' ]);

/// Label
label() => px([ identifier, ':' ]);

/// Break
breakStatement() => px([ 'break', optional(identifier), ';' ]);

/// Continue
continueStatement() => px([ 'continue', optional(identifier), ';' ]);

/// Assert
assertStatement() =>
    px([ 'assert', '(', conditionalExpression, ')', ';' ]);

/// Libraries and Scripts
topLevelDefinition() =>
    or([
         classDefinition,
         typeAlias,
         and([ 'external', functionSignature, ';' ]),
         and([ 'external', getterSignature, ';' ]),
         and([ 'external', setterSignature, ';' ]),
         and([ functionSignature, functionBody ]),
         and([ optional(returnType),
               getOrSet,
               identifier,
               formalParameterList,
               functionBody
            ]),
        and([ or([ 'final', 'const']),
              optional(type),
              staticFinalDeclarationList,
              ';'
           ]),
        and([ variableDeclaration, ';' ])
     ]);

getOrSet() =>
    or([
         'get',
         'set'
      ]);

libraryDefinition() =>
    px([
         optional(libraryName),
         zeroOrMore(importOrExport),
         zeroOrMore(partDirective),
         zeroOrMore(topLevelDefinition)
      ]);

scriptTag() => print('WHAT? scriptTag'); // TODO: px([ '#!', zeroOrMore(not(NEWLINE)), NEWLINE ]);

libraryName() =>
    px([ metadata, 'library', identifier,
         zeroOrMore(and([ '.', identifier ])),
         ';'
      ]);

importOrExport() =>
    or([ libraryImport,
         libraryExport
      ]);

/// Imports
libraryImport() =>
    px([ metadata, 'import', uri, optional(and([ 'as', identifier ])),
         zeroOrMore(combinator), ';'
      ]);

combinator() =>
    or([
        and([ 'show', identifierList ]),
        and([ 'hide', identifierList ])
      ]);

identifierList() =>
    px([ identifier, zeroOrMore(and([ ',', identifier ])) ]);

/// Exports
libraryExport() =>
    px([ metadata, 'export', uri, zeroOrMore(combinator), ';' ]);

/// Parts
partDirective() =>
    px([ metadata, 'part', stringLiteral, ';' ]);

partHeader() =>
    px([ metadata, 'part', 'of', identifier,
         zeroOrMore(and([ '.', identifier ])), ';'
      ]);

partDeclaration() =>
    px([ partHeader, zeroOrMore(topLevelDefinition), EOF ]);

/// URIs
uri() => stringLiteral;

/// Typedef
typeAlias() =>
    px([ metadata, 'typedef', typeAliasBody ]);

typeAliasBody() => functionTypeAlias;

functionTypeAlias() =>
    px([ functionPrefix,
         optional(typeParameters),
         formalParameterList,
         ';'
      ]);

functionPrefix() =>
    px([ optional(returnType), identifier ]);

getterSignature() =>
    px([ optional(type), 'get', identifier ]);

setterSignature() =>
    px([ optional(returnType), 'set', identifier,  formalParameterList ]);


dartProgram()=>
    or([
         libraryDefinition,
         partDeclaration
      ]);
EOF() => print('WHAT? EOF');

main(){
  var tokens = [new Token('var'), new Identifier()..value ='bla',
                new Token(','), new Identifier()..value ='foo' ];
  var parser = variableDeclaration();

  for(final t in tokens){
    parser = parser.derive(t);
  }
  print(parser.toAst());
}
