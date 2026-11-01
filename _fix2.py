p = r'E:\javaclass\posttest\chuyu_toolapp\lib\modules\format_convert\format_converter.dart'
lines = open(p, encoding='utf-8').read().splitlines()
depth = 0
for i, line in enumerate(lines, 1):
    d = line.count('{') - line.count('}')
    old = depth
    depth += d
    if depth < 0:
        print(f'NEGATIVE at line {i}: {line!r} (was {old})')
        break
print('final depth', depth)
