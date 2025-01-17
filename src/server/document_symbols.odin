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


get_document_symbols :: proc(document: ^common.Document) -> []DocumentSymbol {
	using analysis

	ast_context := make_ast_context(document.ast, document.imports, document.package_name, document.uri.uri)

	get_globals(document.ast, &ast_context)

	symbols := make([dynamic]DocumentSymbol, context.temp_allocator)

	package_symbol: DocumentSymbol

	if len(document.ast.decls) == 0 {
		return {}
	}

	package_symbol.kind = .Package
	package_symbol.name = path.base(document.package_name, false, context.temp_allocator)
	package_symbol.range = {
		start = {
			line = document.ast.decls[0].pos.line,
		},
		end = {
			line = document.ast.decls[len(document.ast.decls) - 1].end.line,
		},
	}
	package_symbol.selectionRange = package_symbol.range

	children_symbols := make([dynamic]DocumentSymbol, context.temp_allocator)

	for k, global in ast_context.globals {

		symbol: DocumentSymbol
		symbol.range = common.get_token_range(global.expr, ast_context.file.src)
		symbol.selectionRange = symbol.range
		symbol.name = k

		#partial switch v in global.expr.derived {
		case ^ast.Struct_Type:
			symbol.kind = .Struct
		case ^ast.Proc_Lit, ^ast.Proc_Group:
			symbol.kind = .Function
		case ^ast.Enum_Type, ^ast.Union_Type:
			symbol.kind = .Enum
		case:
			symbol.kind = .Variable
		}

		append(&children_symbols, symbol)
	}

	package_symbol.children = children_symbols[:]

	append(&symbols, package_symbol)

	return symbols[:]
}
