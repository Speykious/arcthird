# Arcthird

> A modern and more abstract version of the Arcsecond library made with Coffeescript.

[Arcsecond](https://github.com/francisrstokes/arcsecond) is a simple parsing library inspired by Haskell's [Parsec](https://wiki.haskell.org/Parsec), made from scratch by francisrstrokes who runs the [LLJS](https://www.youtube.com/channel/UC56l7uZA209tlPTVOJiJ8Tw) YouTube channel.

**Arcthird** makes it more abstract by introducing a new class called `PStream`, from which your parsers are gonna parse from. This allows for example to make a parser of tokens, represented as JS objects.

The documentation is still very empty. It will get more full once I have more free time. If you'd like to contribute, don't hesitate to create pull requests!

# Minor changes in functions

I've decided to change some of the functions from Arcsecond. Overall:
- The `ParserState` is stored in its own class. Therefore:
  - `createParserState` is replaced by the `ParserState` constructor;
  - `updateError` is replaced by the `errorify` method;
  - `updateResult` is replaced by the `resultify` method;
  - `updateData` is replaced by the `dataify` method;
  - `updateParserState` is replaced by the `update` method.
- The `Parser`'s `run` method is called `parse`, and has to take a `PStream`. Thus the curried `parse` function also takes a `PSteam` as an argument.
- For string / buffer / typed array specific parsers from Arcsecond, I created a `StringPStream` class instance of `PSteam`. So you would write for example
  ```js
  char('h').parse(new StringPStream("hello world"))
  parse(str("hello"))(new StringPStream("hello world"))
  ```
- Because writing `new StringPStream` everytime would be kinda annoying, I created the `strparse` function to directly take a string instead:
  ```js
  strparse(str("hello"))("hello world")
  ```
- There is no `many1` function. Instead, there is `atLeast` and `atLeast1`, which is more general.

# Classes

## PStream

`PStream` is an abstract class which is gonna be the input stream of every parser you're gonna use and create.
```haskell
-- This is just for type annotation
class PStream
  constructor :: t -> PStream t
  length :: PStream t ~> () -> Int
  elementAt :: PStream t ~> Int -> a
  next :: PStream t ~> () -> a
  nexts :: PStream t ~> Int -> [a]
```
- `next`: gives the next element.
- `nexts`: gives an array of the next n elements.

The `next` and `nexts` methods are automatically defined in terms of `elementAt`. Although they aren't used anywhere as I didn't realize that I had used the `index` property of the `ParserState` class all this time. Replacing that with the `index` property of the `PStream` is an improvement to make in the future.

Because it is an abstract class, you cannot use it as is, you have to create your own extension and implement the `length` and `elementAt` functions yourself. For example:
```js
class NumberStream extends PStream {
  constructor(target) {
    if (!(target instanceof Array))
      throw new TypeError("Target must be an Array");
    super(target);
  }

  length() {
    return this.structure.length;
  }

  elementAt(i) {
    try {
      return this.structure[i];
    } catch (err) {
      return null;
    }
  }
}

const nstream = new NumberStream([1, 2, 3, 42, 69]);
console.log(nstream.next());       // 1
console.log(nstream.nexts(2));     // [2, 3]
console.log(nstream.elementAt(0)); // 1
console.log(nstream.nexts(3));     // [42, 69, null]
console.log(nstream.next());       // null
console.log(nstream.length());     // 5
```

## Parser
The type of a parser as used in the documentation is different from Arcsecond. Because of the new abstraction, there is now a new generic type to take into account: `t` as a `PStream`.
```haskell
-- This is just for type annotation
class Parser
  constructor :: PStream t => (ParserState t * d -> ParserState t a d) -> Parser t a d
  parse :: PStream t => Parser t a d ~> t -> ParserState t a d
  fork :: PStream t => Parser t a d ~> (t, (ParserState t a d -> x), (ParserState t a d -> y)) -> (Either x y)
  map :: PStream t => Parser t a d ~> (a -> b) -> Parser t b d
  chain :: PStream t => Parser t a d ~> (a -> Parser t b d) -> Parser t b d
  ap :: PStream t => Parser t a d ~> Parser t (a -> b) d -> Parser t b d
  errorMap :: PStream t => Parser t a d ~> ({d, String, Int} -> String) -> Parser t a d
  errorChain :: PStream t => Parser t a d ~> ({d, String, Int} -> Parser t a d) -> Parser t a d
  mapFromData :: PStream t => Parser t a d ~> ({a, d} -> b) -> Parser t b d
  chainFromData :: PStream t => Parser t a d ~> ({a, d} -> Parser t b e) -> Parser t b e
  mapData :: PStream t => Parser t a d ~> (d -> e) -> Parser t a e
  of :: PStream t => x -> Parser t x d
```
All the errors returned in parser states are strings. Now this doesn't change anything from Arcsecond, although Arcsecond explicitly allowed for different error types. After verification, I realized that my code does also allow for different error types; however, this isn't reflected in the documentation where errors are described as strings even for parser combinators.

- `constructor`: constructs a new parser by taking a `ParserState` transformer as an argument, which is a function that takes a `ParserState` and returns a new `ParserState`.
  ```js
  const consume = new Parser(state => new ParserState({
    ...state.props(),
    index: state.target.length()
  }));
  ```
- `parse`: directly parses a `PStream` into a `ParserState`.
  ```js
  char('a').parse(new StringPStream("abc"));
  ```

# Parser Generators

## char
```haskell
char :: StringPStream t => Char -> Parser t Char d
```
Parses a single character.
```js
strparse(char('h'))("hello world")
// -> ParserState result='h' index=1
```

## anyChar
```haskell
anyChar :: StringPStream t => Parser t Char d
```
Parses any character.
```js
strparse(anyChar)("bruh")
// -> ParserState result='b' index=1
```

## peek
```haskell
peek :: PStream t => Parser t a d
```
Returns the element at the current index as a result without moving forward.
```js
strparse(peek)("something")
// -> ParserState result='s' index=0
```

## str
```haskell
str :: StringPStream t => String -> Parser t String d
```

## regex
```haskell
regex :: StringPStream t => RegExp -> Parser t String d
```

## digit
```haskell
digit :: StringPStream t => Parser t String d
```

## digits
```haskell
digits :: StringPStream t => Parser t String d
```

## letter
```haskell
letter :: StringPStream t => Parser t String d
```

## letters
```haskell
letters :: StringPStream t => Parser t String d
```

## anyOfString
```haskell
anyOfString :: StringPStream t => String -> Parser t Char d
```

## endOfInput
```haskell
endOfInput :: PStream t => Parser t Null d
```

## whitespace
```haskell
whitespace :: StringPStream t => Parser t String d
```

## optionalWhitespace
```haskell
optionalWhitespace :: StringPStream t => Parser t String d
```


# Parser Combinators

## getData
```haskell
getData :: PStream t => Parser t a d
```

## setData
```haskell
setData :: PStream t => d -> Parser t a d
```

## mapData
```haskell
mapData :: PStream t => (d -> e) -> Parser t a e
```

## withData
```haskell
withData :: PStream t => Parser t a d -> e -> Parser t a e
```

## pipe
```haskell
pipe :: PStream t => [Parser t * *] -> Parser t * *
```

## compose
```haskell
compose :: PStream t => [Parser t * *] -> Parser t * *
```

## tap
```haskell
tap :: PStream t => (ParserState t a d -> IO ()) -> Parser t a d
```

## parse
```haskell
parse :: PStream t => Parser t a d -> t -> Either String a
```

## strparse
```haskell
strparse :: StringPStream t => Parser t a d -> String -> Either String a
```

## decide
```haskell
decide :: PStream t => (a -> Parser t b d) -> Parser t b d
```

## fail
```haskell
fail :: PStream t => String -> Parser t a d
```

## succeedWith
```haskell
succeedWith :: PStream t => a -> Parser t a d
```

## either
```haskell
either :: PStream t => Parser t a d -> Parser t (Either String a) d
```

## coroutine
```haskell
coroutine :: PStream t => (() -> Iterator (Parser t a d)) -> Parser t a d
```

## exactly
```haskell
exactly :: PStream t => Int -> Parser t a d -> Parser t [a] d
```

## many
```haskell
many :: PStream t => Parser t a d -> Parser t [a] d
```

## atLeast
```haskell
atLeast :: PStream t => Int -> Parser t a d -> Parser t [a] d
```

## atLeast1
```haskell
atLeast1 :: PStream t => Parser t a d -> Parser t [a] d
```

## mapTo
```haskell
mapTo :: PStream t => (a -> b) -> Parser t b d
```

## errorMapTo
```haskell
errorMapTo :: PStream t => ({d, String, Int} -> String) -> Parser t a d
```

## namedSequenceOf
```haskell
namedSequenceOf :: PStream t => [(String, Parser t * *)] -> Parser t (StrMap *) d
```

## sequenceOf
```haskell
sequenceOf :: PStream t => [Parser t * *] -> Parser t [*] *
```

## sepBy
```haskell
sepBy :: PStream t => Parser t a d -> Parser t b d -> Parser t [b] d
```

## sepBy1
```haskell
sepBy1 :: PStream t => Parser t a d -> Parser t b d -> Parser t [b] d
```

## choice
```haskell
choice :: PStream t => [Parser t * *] -> Parser t * *
```

## between
```haskell
between :: PStream t => Parser t a d -> Parser t b d -> Parser t c d -> Parser t b d
```

## everythingUntil
```haskell
everythingUntil :: StringPStream t => Parser t a d -> Parser t String d
```

## everyCharUntil
```haskell
everyCharUntil :: StringPStream t => Parser t a d -> Parser t String d
```

## anythingExcept
```haskell
anythingExcept :: StringPStream t => Parser t a d -> Parser t Char d
```

## anyCharExcept
```haskell
anyCharExcept :: StringPStream t => Parser t a d -> Parser t Char d
```

## lookAhead
```haskell
lookAhead :: PStream t => Parser t a d -> Parser t a d
```

## possibly
```haskell
possibly :: PStream t => Parser t a d -> Parser t (a | Null) d
```

## skip
```haskell
skip :: PStream t => Parser t a d -> Parser t a d
```

## recursiveParser
```haskell
recursiveParser :: PStream t => (() -> Parser t a d) -> Parser t a d
```

## takeRight
```haskell
takeRight :: PStream t => Parser t a d -> Parser t b d -> Parser t b d
```

## takeLeft
```haskell
takeLeft :: PStream t => Parser t a d -> Parser t b d -> Parser t a d
```

## toPromise
```haskell
toPromise :: PStream t => ParserState t a d -> Promise (String, Integer, d) a
```

## toValue
```haskell
toValue :: PStream t => ParserState t a d -> a
```
