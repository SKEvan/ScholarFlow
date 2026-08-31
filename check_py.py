import ast, sys
files = [r'd:\ScholarFlow\backend\supabase_service.py', r'd:\ScholarFlow\backend\main.py']
errors = 0
for f in files:
    try:
        ast.parse(open(f, encoding='utf-8').read())
        print(f'OK {f}')
    except SyntaxError as e:
        print(f'FAIL {f}: {e}')
        errors += 1
sys.exit(errors)
