# -*- coding: utf-8 -*-
import sys
path = r"E:\javaclass\posttest\chuyu_toolapp\lib\modules\format_convert\format_converter.dart"
# 源文件用 raw 字符串读取占位 —— 实际内容在 _fmt_src.dart
src = r"E:\javaclass\posttest\_fmt_src.dart"
content = open(src, encoding="utf-8").read()
open(path, "w", encoding="utf-8").write(content)
print("written", len(content))
