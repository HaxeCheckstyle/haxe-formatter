package formatter;

import byte.ByteData;
import haxe.io.Bytes;
import haxe.macro.Expr;
import haxeparser.Data;
import tokentree.TokenTree;
import tokentree.TokenTreeAccessHelper;
import tokentree.utils.TokenTreeCheckUtils;
import formatter.codedata.ParsedCode;
import formatter.codedata.TokenInfo;

using StringTools;
using tokentree.TokenTreeAccessHelper;
using formatter.config.WhitespacePolicy;
