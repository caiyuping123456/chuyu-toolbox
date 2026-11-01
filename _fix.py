import re
p = r'E:\javaclass\posttest\chuyu_toolapp\lib\modules\format_convert\format_converter.dart'
s = open(p, encoding='utf-8').read()
old = """      return '$indent<$tag>${_esc('$val')}</$tag>';"""
new = """      final escVal = _esc('$val');
      return '$indent<$tag>$escVal</$tag>';"""
if old in s:
    s = s.replace(old, new)
    open(p, 'w', encoding='utf-8').write(s)
    print('FIXED')
else:
    print('NOT FOUND')
    for line in s.splitlines():
        if '_esc(' in line:
            print(repr(line))
