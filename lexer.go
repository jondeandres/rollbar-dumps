// Copyright (c) 2015 Andrea Cardaci <cyrus.and@gmail.com>

// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

package main

type tokenType int
type lexerState int

const (
	normal lexerState = iota
	inQuotation
	inEscape
)

type token struct {
	tokenType tokenType
	value     string
}

type parser struct {
	tokens <-chan token
	output map[string]interface{}
}

func lexer(input string) <-chan token { // no checks here...
	position := 0
	state := normal
	tokens := make(chan token)
	var value []byte
	go func() {
		for position < len(input) {
			next := input[position]
			switch state {
			case normal:
				switch next {
				case '^', '*', '+', '=', '~', '@', '&', ',', '{', '}', '[', ']':
					if value != nil {
						tokens <- token{tokenType(text), string(value)}
						value = nil
					}
					tokens <- token{tokenType(next), string(next)}
				case '"':
					state = inQuotation
					if value != nil {
						tokens <- token{tokenType(text), string(value)}
						value = nil
					}
				default:
					value = append(value, next)
				}
			case inQuotation:
				switch next {
				case '"':
					state = normal
					if value != nil {
						tokens <- token{tokenType(text), string(value)}
					} else {
						tokens <- token{tokenType(text), ""}
					}
					value = nil
				case '\\':
					state = inEscape
				default:
					value = append(value, next)
				}
			case inEscape:
				switch next {
				case 'a':
					next = '\a'
				case 'b':
					next = '\b'
				case 'f':
					next = '\f'
				case 'n':
					next = '\n'
				case 'r':
					next = '\r'
				case 't':
					next = '\t'
				case 'v':
					next = '\v'
				case '\\':
					next = '\\'
				case '\'':
					next = '\''
				case '"':
					next = '"'
				}
				value = append(value, next)
				state = inQuotation
			}
			position++
		}
		if value != nil {
			tokens <- token{tokenType(text), string(value)}
			value = nil
		}
		close(tokens)
	}()
	return tokens
}

func (p *parser) Lex(lval *yySymType) int {
	// fetch the next token
	token, ok := <-p.tokens
	if ok {
		// save the value and return the token type
		lval.text = token.value
		return int(token.tokenType)
	} else {
		return 0 // no more tokens
	}
}

func (p *parser) Error(err string) {
	// errors are GDB bugs if the grammar is correct
	panic(err)
}

func parseRecord(data string) map[string]interface{} {
	parser := parser{lexer(data), map[string]interface{}{}}
	yyParse(&parser)
	return parser.output
}
