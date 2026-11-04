"""Motore che espande i template in ricette concrete.

Un template descrive un piatto con alcuni "slot" intercambiabili (proteina,
verdura, cereale, frutta...). Il motore genera le combinazioni, scarta quelle
con ingredienti di stagioni incompatibili (es. asparagi e zucca), ordina le
restanti per varietà e copertura delle stagioni e infine ne sceglie un numero
per tipo di pasto.
"""

from __future__ import annotations

import itertools
import random
import re
from dataclasses import dataclass, field
from types import SimpleNamespace
from typing import Callable

from foods import FOODS_BY_ID

MAIN, BREAKFAST, SNACK = 'main', 'breakfast', 'snack'

# Fasce di macro per porzione considerate plausibili per tipo di pasto.
RANGES = {
    MAIN: dict(kcal=(380, 900), protein=22),
    BREAKFAST: dict(kcal=(220, 650), protein=10),
    SNACK: dict(kcal=(90, 420), protein=4),
}

SEASON_BUCKETS = {
    'inverno': {12, 1, 2},
    'primavera': {3, 4, 5},
    'estate': {6, 7, 8},
    'autunno': {9, 10, 11},
}


@dataclass
class Opt:
    """Una scelta per uno slot: ingredienti più le parole per titolo e passi."""

    key: str
    label: str
    ing: dict[str, float]
    protein: str | None = None
    attrs: dict = field(default_factory=dict)

    def ns(self) -> SimpleNamespace:
        return SimpleNamespace(key=self.key, label=self.label, **self.attrs)


def opt(key: str, label: str, ing: dict[str, float], protein: str | None = None, **attrs) -> Opt:
    return Opt(key, label, dict(ing), protein, attrs)


@dataclass
class Template:
    key: str
    type: str
    name: str
    steps: list[str]
    base: dict[str, float] = field(default_factory=dict)
    slots: dict[str, list[Opt]] = field(default_factory=dict)
    protein: str | None = None
    fridge: int = 3
    freeze: bool = False
    minutes: int = 30
    tags: list[str] = field(default_factory=list)
    max: int = 15
    # Ritorna True per scartare una combinazione (dict slot -> Opt).
    exclude: Callable[[dict[str, Opt]], bool] | None = None


@dataclass
class Recipe:
    id: str
    name: str
    type: str
    ingredients: dict[str, float]
    steps: list[str]
    protein: str
    fridge: int
    freeze: bool
    minutes: int
    tags: list[str]
    template: str = ''
    opt_keys: tuple[str, ...] = ()

    def macros(self):
        k = p = c = f = 0.0
        for fid, g in self.ingredients.items():
            food = FOODS_BY_ID[fid]
            k += food.kcal * g / 100
            p += food.p * g / 100
            c += food.c * g / 100
            f += food.f * g / 100
        return k, p, c, f

    def season(self) -> set[int] | None:
        """Mesi in cui tutti gli ingredienti stagionali rilevanti sono di
        stagione; None se la ricetta non ne contiene."""
        months = None
        for fid, g in self.ingredients.items():
            s = FOODS_BY_ID[fid].season
            if s is None or g < 15:
                continue
            months = set(s) if months is None else months & set(s)
        return months


def slug(s: str) -> str:
    s = s.lower()
    for a, b in [('à', 'a'), ('è', 'e'), ('é', 'e'), ('ì', 'i'), ('ò', 'o'), ('ù', 'u')]:
        s = s.replace(a, b)
    return re.sub(r'[^a-z0-9]+', '_', s).strip('_')


def _fmt(text: str, ctx: dict) -> str:
    out = text.format(**ctx)
    out = re.sub(r'\s+', ' ', out).strip()
    out = re.sub(r'\s+([,.;:])', r'\1', out)
    return out[0].upper() + out[1:] if out else out


def expand(t: Template) -> list[Recipe]:
    """Tutte le combinazioni valide del template."""
    names = list(t.slots)
    out = []
    for combo in itertools.product(*(t.slots[n] for n in names)):
        chosen = dict(zip(names, combo))
        if t.exclude and t.exclude(chosen):
            continue
        ing: dict[str, float] = dict(t.base)
        for o in combo:
            for fid, g in o.ing.items():
                ing[fid] = ing.get(fid, 0) + g
        ctx = {n: o.ns() for n, o in chosen.items()}
        protein = t.protein
        if protein is None:
            protein = next((o.protein for o in combo if o.protein), None)
        if protein is None:
            raise ValueError(f'{t.key}: proteina principale non definita')
        rid = 'r_' + '_'.join([t.key] + [o.key for o in combo])
        r = Recipe(
            id=rid,
            name=_fmt(t.name, ctx),
            type=t.type,
            ingredients={k: round(v) for k, v in ing.items() if v > 0},
            steps=[_fmt(s, ctx) for s in t.steps if _fmt(s, ctx)],
            protein=protein,
            fridge=t.fridge,
            freeze=t.freeze,
            minutes=t.minutes,
            tags=list(t.tags),
            template=t.key,
            opt_keys=tuple(f'{n}:{o.key}' for n, o in chosen.items()),
        )
        s = r.season()
        if s is not None and len(s) < 2:
            continue  # ingredienti di stagioni che non si sovrappongono
        out.append(r)
    return out


def _buckets(r: Recipe) -> set[str]:
    s = r.season()
    if s is None:
        return {'sempre'}
    return {b for b, months in SEASON_BUCKETS.items() if len(months & s) >= 2}


def order_for_variety(t: Template, recipes: list[Recipe], rnd: random.Random) -> list[Recipe]:
    """Ordina le combinazioni in modo che le prime siano le più varie:
    opzioni poco usate e stagioni poco coperte vengono prima."""
    remaining = list(recipes)
    rnd.shuffle(remaining)
    used: dict[str, int] = {}
    bucket_count: dict[str, int] = {}
    ordered = []
    while remaining:
        def score(r: Recipe) -> float:
            opt_use = sum(used.get(p, 0) for p in r.opt_keys)
            b = _buckets(r) or {'sempre'}
            season_use = min(bucket_count.get(x, 0) for x in b)
            return opt_use + 0.8 * season_use
        best = min(remaining, key=score)
        remaining.remove(best)
        ordered.append(best)
        for p in best.opt_keys:
            used[p] = used.get(p, 0) + 1
        for x in _buckets(best) or {'sempre'}:
            bucket_count[x] = bucket_count.get(x, 0) + 1
    return ordered


def select(templates: list[Template], quota: dict[str, int], seed: int = 7) -> list[Recipe]:
    """Sceglie le ricette a giro tra i template finché ogni tipo raggiunge la
    sua quota, rispettando il massimo per template."""
    rnd = random.Random(seed)
    pools = {}
    for t in templates:
        pools[t.key] = order_for_variety(t, expand(t), rnd)
    chosen: list[Recipe] = []
    names: set[str] = set()
    ids: set[str] = set()
    for typ, q in quota.items():
        ts = [t for t in templates if t.type == typ]
        taken = {t.key: 0 for t in ts}
        idx = {t.key: 0 for t in ts}
        count = 0
        progress = True
        while count < q and progress:
            progress = False
            for t in ts:
                if count >= q:
                    break
                pool = pools[t.key]
                while idx[t.key] < len(pool) and taken[t.key] < t.max:
                    r = pool[idx[t.key]]
                    idx[t.key] += 1
                    if r.name.lower() in names or r.id in ids:
                        continue
                    chosen.append(r)
                    names.add(r.name.lower())
                    ids.add(r.id)
                    taken[t.key] += 1
                    count += 1
                    progress = True
                    break
        if count < q:
            print(f'ATTENZIONE: {typ} solo {count}/{q} ricette disponibili')
    return chosen


def tags_for(r: Recipe) -> list[str]:
    diets = {FOODS_BY_ID[f].diet for f in r.ingredients}
    tags = []
    if not diets & {'meat', 'fish'}:
        tags.append('vegetariano')
        if not diets & {'dairy', 'egg', 'honey'}:
            tags.append('vegano')
    if not any(FOODS_BY_ID[f].gluten for f in r.ingredients):
        tags.append('senza glutine')
    if not diets & {'dairy'}:
        tags.append('senza lattosio')
    return tags + [t for t in r.tags if t not in tags]


def instructions(r: Recipe) -> str:
    lines = [f'{i}. {s}' for i, s in enumerate(r.steps, 1)]
    keep = f'Meal prep: si conserva {r.fridge} giorn{"o" if r.fridge == 1 else "i"} in frigo in contenitori ermetici'
    keep += '; si può congelare in porzioni.' if r.freeze else '.'
    return '\n'.join(lines + [keep])


def validate(recipes: list[Recipe]) -> list[str]:
    problems = []
    for r in recipes:
        for fid in r.ingredients:
            if fid not in FOODS_BY_ID:
                problems.append(f'{r.id}: alimento sconosciuto {fid}')
        if problems:
            continue
        k, p, _, _ = r.macros()
        lo, hi = RANGES[r.type]['kcal']
        if not lo <= k <= hi:
            problems.append(f'{r.id}: {k:.0f} kcal fuori da {lo}-{hi}')
        if p < RANGES[r.type]['protein']:
            problems.append(f'{r.id}: proteine {p:.0f} g basse')
        if re.search(r'\{|\}', r.name + ''.join(r.steps)):
            problems.append(f'{r.id}: segnaposto non risolto')
    return problems
