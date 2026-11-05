"""Genera assets/db/foods.json e assets/db/recipes.json.

Uso (dalla radice del progetto):
    python tool/recipe_db/build.py            # genera e valida
    python tool/recipe_db/build.py --check    # solo validazione e statistiche
    python tool/recipe_db/build.py --pack templates_primi   # prova un pacchetto

I pacchetti di template sono i moduli `templates_*.py` di questa cartella,
ognuno con una lista `TEMPLATES`.
"""

import argparse
import importlib
import json
import pathlib
import re
import sys
from collections import Counter

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from engine import (BREAKFAST, MAIN, SEASON_BUCKETS, SNACK, Recipe, expand, instructions,  # noqa: E402
                    select, tags_for, validate)
from foods import FOODS, FOODS_BY_ID, register  # noqa: E402
from legacy import LEGACY  # noqa: E402

OUT = HERE.parent.parent / 'assets' / 'db'
TARGET = {MAIN: 620, BREAKFAST: 190, SNACK: 191}


def load_templates(only: str | None = None):
    out = []
    for path in sorted(HERE.glob('templates_*.py')):
        if only and path.stem != only:
            continue
        mod = importlib.import_module(path.stem)
        register(getattr(mod, 'EXTRA_FOODS', []))
        out.extend(mod.TEMPLATES)
    keys = Counter(t.key for t in out)
    dup = [k for k, n in keys.items() if n > 1]
    if dup:
        sys.exit(f'Chiavi di template duplicate: {dup}')
    return out


def legacy_recipes() -> list[Recipe]:
    out = []
    for r in LEGACY:
        steps = [s.strip() for s in re.split(r'(?<=\.)\s+(?=[A-Z])', r['how']) if s.strip()]
        out.append(Recipe(
            id=r['id'], name=r['name'], type=r['type'],
            ingredients={k: round(v) for k, v in r['ingredients'].items()},
            steps=steps, protein=r['protein'], fridge=r['fridge'], freeze=r['freeze'],
            minutes=r['minutes'], tags=[], template='legacy',
            fixed_servings=r.get('fixedServings')))
    return out


def food_json(f):
    return {
        'id': f.id,
        'name': f.name,
        'category': f.cat,
        'per100g': {'kcal': f.kcal, 'protein': f.p, 'carbs': f.c, 'fat': f.f},
        'unitGrams': f.unit,
        'unitName': f.unit_name,
        'packageGrams': f.pack,
        'seasonMonths': list(f.season) if f.season else [],
    }


def recipe_json(r: Recipe):
    return {
        'id': r.id,
        'name': r.name,
        'type': r.type,
        'ingredients': [{'foodId': k, 'grams': v} for k, v in r.ingredients.items()],
        'instructions': instructions(r),
        'mainProtein': r.protein,
        'fridgeDays': r.fridge,
        'freezable': r.freeze,
        'prepMinutes': r.minutes,
        'tags': tags_for(r),
        'source': 'builtin',
        **({'fixedServings': r.fixed_servings} if r.fixed_servings else {}),
    }


def stats(recipes: list[Recipe]):
    print(f'Ricette: {len(recipes)}')
    print('  per tipo:', dict(Counter(r.type for r in recipes)))
    print('  per proteina (pasti principali):',
          dict(Counter(r.protein for r in recipes if r.type == MAIN).most_common()))
    for typ in (MAIN, BREAKFAST, SNACK):
        rs = [r for r in recipes if r.type == typ]
        cov = {}
        for b, months in SEASON_BUCKETS.items():
            cov[b] = sum(1 for r in rs if (s := r.season()) is None or len(s & months) >= 2)
        print(f'  {typ}: adatte per stagione {cov}, senza ingredienti stagionali '
              f'{sum(1 for r in rs if r.season() is None)}')
    used = {f for r in recipes for f in r.ingredients}
    unused = [f.id for f in FOODS if f.id not in used]
    if unused:
        print('  alimenti non usati:', ', '.join(unused))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--pack')
    ap.add_argument('--all', action='store_true', help='con --pack: valida tutte le combinazioni')
    args = ap.parse_args()

    templates = load_templates(args.pack)
    if args.pack:
        recipes = [r for t in templates for r in (expand(t) if args.all else [])]
        if not args.all:
            from engine import order_for_variety
            import random
            rnd = random.Random(7)
            for t in templates:
                pool = order_for_variety(t, expand(t), rnd)
                print(f'{t.key}: {len(pool)} combinazioni valide (max {t.max})')
                recipes += pool[:t.max]
        problems = validate(recipes)
        print('\n'.join(problems) or 'Nessun problema.')
        stats(recipes)
        for r in recipes[:3]:
            print('\n' + json.dumps(recipe_json(r), ensure_ascii=False, indent=1))
        return

    legacy = legacy_recipes()
    quota = {t: n - sum(1 for r in legacy if r.type == t) for t, n in TARGET.items()}
    generated = select(templates, quota)
    legacy_names = {r.name.lower() for r in legacy}
    generated = [r for r in generated if r.name.lower() not in legacy_names]
    recipes = legacy + generated

    problems = validate(recipes)
    if problems:
        print('\n'.join(problems))
        sys.exit(f'{len(problems)} problemi')
    ids = Counter(r.id for r in recipes)
    assert all(n == 1 for n in ids.values()), 'id duplicati'
    stats(recipes)
    if args.check:
        return

    OUT.mkdir(parents=True, exist_ok=True)
    used = {f for r in recipes for f in r.ingredients}
    assert used <= FOODS_BY_ID.keys()
    (OUT / 'foods.json').write_text(
        json.dumps([food_json(f) for f in FOODS], ensure_ascii=False, indent=1), encoding='utf-8')
    (OUT / 'recipes.json').write_text(
        json.dumps([recipe_json(r) for r in recipes], ensure_ascii=False, indent=1), encoding='utf-8')
    print(f'Scritti {OUT / "foods.json"} e {OUT / "recipes.json"}')


if __name__ == '__main__':
    main()
