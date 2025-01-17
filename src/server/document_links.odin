package server

import "core:odin/parser"
import "core:odin/ast"
import "core:odin/tokenizer"
import "core:fmt"
import "core:log"
import "core:strings"
import path "core:path/slashpath"
import "core:mem"
import "core:strconv"
import "core:path/filepath"
import "core:sort"
import "core:slice"
import "core:os"


import "shared:common"
import "shared:index"
import "shared:analysis"

get_document_links :: proc(document: ^common.Document) -> ([]DocumentLink, bool) {
	using analysis

	links := make([dynamic]DocumentLink, 0, context.temp_allocator)

	for imp in document.ast.imports {
		if len(imp.relpath.text) <= 1 {
			continue
		}

		e := strings.split(imp.relpath.text[1:len(imp.relpath.text)-1], ":", context.temp_allocator)

		if len(e) != 2 {
			continue
		}

		if e[0] != "core" {
			continue
		}

		//Temporarly assuming non unicode
		node := ast.Node {
			pos = {
				offset = imp.relpath.pos.offset + 1,
				column = imp.relpath.pos.column + 1,
				line = imp.relpath.pos.line,
			},
			end = {
				offset = imp.relpath.pos.offset + len(imp.relpath.text) - 1, 
				column = imp.relpath.pos.column + len(imp.relpath.text) - 1,
				line = imp.relpath.pos.line,
			},
		}

		range := common.get_token_range(node, string(document.text))

		link := DocumentLink {
			range = range,
			target = fmt.tprintf("https://pkg.odin-lang.org/%v/%v", e[0], e[1]),
			tooltip = "Documentation",
		}

		append(&links, link)
	}

	return links[:], true
}
