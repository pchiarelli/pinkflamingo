# -*- coding: utf-8 -*-
import json, re, unicodedata
from collections import Counter

raw = open('/tmp/pf_raw.json').read().split('\n',1)[1]
data = json.loads(raw)

def na(s):  # normalize accents + lower
    s=unicodedata.normalize('NFD',s)
    s=''.join(c for c in s if unicodedata.category(c)!='Mn')
    return s.lower()

PHRASES = {
    'harrypotter':'Harry Potter','cartadehogwarts':'Carta de Hogwarts',
    'championsleague':'Champions League','galinhapintadinha':'Galinha Pintadinha',
    'brancadeneve':'Branca de Neve','patrulhacanina':'Patrulha Canina',
    'pequenasereia':'Pequena Sereia','jujutsukaisen':'Jujutsu Kaisen',
    'jujutsikaisen':'Jujutsu Kaisen','brawlstars':'Brawl Stars',
    'mashaeourso':'Masha e o Urso','poderosochefinho':'Poderoso Chefinho',
    'poderosochefinhk':'Poderoso Chefinho','minicooper':'Mini Cooper',
    'fadamadrinha':'Fada Madrinha','stitcheangel':'Stitch e Angel',
    'rodagigante':'Roda gigante','maquinadeescrever':'Máquina de escrever',
    'varinhadasvarinhas':'Varinha das varinhas','casamagicadagabby':'Casa Mágica da Gabby',
    'bolaespelhada':'Bola espelhada','tocodemadeira':'toco de madeira',
    'cestadepalha':'Cesta de palha','superherois':'Super Heróis',
    'minicooper':'Mini Cooper',
}

VOCAB = """boleira bandeja bolo fake display capa painel mesa vaso cilindro letra numero
led vela suporte luminaria tapete manta cabana podio claquete carta cone ripado quadrado
redondo redonda romano sextavada desmontavel ceramica vidro lona solteiro andares andar
arranjo bexigas borboleta seda concha abobora folhagem rosa rosas lirio margarida astromelia
donuts caixa bola espelhada maquina escrever varinha varinhas roda gigante carro vermelho
pelucia eva mdf castical alta grande pequeno piruliteiro friso dourado tampo trio boiserie
boserie madeira toco palha cesta arco iris super herois retangular
pequena sereia branca neve patrulha canina galinha pintadinha champions league harry potter
hogwarts frozen minnie mickey minions grinch wandinha cinderela princesas unicornio futebol
squirtle luigi mario bruni maui moana stitch angel bita magali monstrinhos wicked halloween
country masha urso poderoso chefinho brawl stars minecraft jujutsu kaisen cooper mini gabby
de do da das dos com sem para no na os as
azul verde vermelha vermelho amarela amarelo laranja branca branco preta preto dourada dourado
prata lilas roxa roxo bege marsala terracota tiffany marinha claro escuro candy neon antigo
bic folha musgo rose marinho em""".split()

CS = set("p m g gg pp un".split())
KNOWN = set(na(w) for w in VOCAB) | CS

def best_split(s):
    n=len(s); INF=float('inf')
    cost=[INF]*(n+1); cost[0]=0; back=[0]*(n+1)
    low=na(s)
    for i in range(1,n+1):
        last = (i==n)
        for j in range(max(0,i-16),i):
            frag=low[j:i]
            if frag in KNOWN:
                c=cost[j]+1
            else:
                pen = 1 if last and len(frag)<=6 else 3   # tolerate truncated tail
                c=cost[j]+pen+len(frag)*2
            if c<cost[i]:
                cost[i]=c; back[i]=j
    toks=[]; i=n
    while i>0:
        j=back[i]; toks.append(s[j:i]); i=j
    return toks[::-1]

JUNK = re.compile(r'(invent|^\d{2}/\d{2}|produto$|varia|^tipo$|estoque)', re.I)

def segment(name):
    name=name.strip()
    if not name or JUNK.search(na(name)): return None
    trailing=''
    if name.endswith('...'): name=name[:-3]; trailing='…'
    star=name.startswith('*')
    if star: name=name[1:]
    m=re.match(r'^(.*?)(\(.*)$', name)
    core=name; paren=''
    if m: core=m.group(1); paren=' '+m.group(2)
    lc=na(core)
    if lc in PHRASES:
        out=PHRASES[lc]
    else:
        out=' '.join(best_split(core))
    out=(out+paren).strip()
    out=re.sub(r'\s+',' ',out)
    out=re.sub(r'\(\s+','(',out); out=re.sub(r'\s+\)',')',out)
    out=re.sub(r'(\d)cm',r'\1 cm',out)
    # targeted post-fixes for known truncation artifacts
    out=re.sub(r'\bde smont', 'desmont', out)
    out=re.sub(r'\bp lissada', 'plissada', out)
    out=out.replace(' - ', '-')
    out=re.sub(r'\s*\+\s*c…$', '…', out)
    out=re.sub(r'\s+…$', '…', out)
    if out: out=out[0].upper()+out[1:]
    return ('* ' if star else '')+out+trailing

def categorize(name):
    n=na(name)
    if name.startswith('* ') or 'arranjo' in n or 'bexiga' in n: return 'Itens decorativos'
    if 'bandeja' in n: return 'Bandejas'
    if 'boleira' in n: return 'Boleiras'
    if 'bolo fake' in n or n.startswith('bolo'): return 'Bolos fakes'
    if 'bonec' in n or 'pelucia' in n: return 'Bonecos'
    if 'display' in n: return 'Displays'
    if any(w in n for w in ['lirio','rosa artificial','rose artificial','margarida','astromelia','folhagem','flor ']): return 'Flores artificiais'
    if 'led' in n or n.startswith('letra') or n.startswith('numero'): return 'Leds'
    if 'mesa' in n: return 'Mesas'
    if 'painel' in n: return 'Painéis'
    if 'tapete' in n: return 'Tapetes'
    if 'vaso' in n: return 'Vasos'
    return 'Itens decorativos'

out=[]; seen=set()
for x in data:
    nm=segment(x['raw'])
    if nm is None: continue
    if x['raw'] in seen: continue
    seen.add(x['raw'])
    price=0.0
    if x['venda']:
        p=x['venda'].replace('R$','').replace('.','').replace(',','.')
        try: price=float(p)
        except: price=0.0
    out.append({'name':nm,'price':price,'category':categorize(nm)})

print('TOTAL',len(out))
for k,v in sorted(Counter(x['category'] for x in out).items(), key=lambda a:-a[1]):
    print(f'  {k}: {v}')
print('--- samples ---')
for x in out[:45]:
    print(f"{x['category'][:10]:10} | R${x['price']:>7.2f} | {x['name']}")
json.dump(out, open('/tmp/pf_products.json','w'), ensure_ascii=False, indent=2)

# ---- emit Dart seed file ----
def dart_str(s):
    return "'" + s.replace('\\','\\\\').replace("'","\\'").replace('$','\\$') + "'"

CATS = [
 ('Bandejas','Bandejas retangulares, sextavadas e orgânicas.'),
 ('Boleiras','Boleiras pequenas e grandes.'),
 ('Bolos fakes','Bolos fakes de 2 a 4 andares.'),
 ('Bonecos','Bonecos de vinil, de pelúcia e de feltro.'),
 ('Displays','Displays em mdf.'),
 ('Flores artificiais','Folhagem e flores em geral.'),
 ('Itens decorativos','Bonecos, displays, quadros, velas, luminárias e muito mais!'),
 ('Leds','Letras e números de led.'),
 ('Mesas','Mesas retangulares, cones, cilindros e de ferro.'),
 ('Painéis','Capas de painel redondo, quadrado e retangular.'),
 ('Tapetes','Tapetes e mantas.'),
 ('Vasos','Vasos pequenos, médios e de cerâmica.'),
]
KITS = ['Barbie','Bolofofos','Call of Duty','Casa Mágica da Gabby','Champions League',
 'Cinderela','Descendentes','Dragon Ball','Frozen','Galinha Pintadinha','Harry Potter',
 'Minnie','Patrulha Canina','Princesas','Stitch','Unicórnio']

lines=[]
lines.append('// GENERATED FILE — seed data extracted from report001.pdf (Pink Flamingo inventory).')
lines.append('// Regenerate with tools/segment.py. Truncated names (…) are truncated in the source PDF.')
lines.append("import '../models/category.dart';")
lines.append("import '../models/product.dart';")
lines.append("import '../models/kit.dart';")
lines.append('')
lines.append('const List<Category> seedCategories = [')
for name,desc in CATS:
    lines.append(f"  Category(name: {dart_str(name)}, description: {dart_str(desc)}),")
lines.append('];')
lines.append('')
lines.append('const List<Product> seedProducts = [')
for x in out:
    lines.append(f"  Product(name: {dart_str(x['name'])}, price: {x['price']}, category: {dart_str(x['category'])}),")
lines.append('];')
lines.append('')
lines.append('const List<Kit> seedKits = [')
for k in KITS:
    lines.append(f"  Kit(name: {dart_str(k)}),")
lines.append('];')
lines.append('')
open('/Users/pietro/Projetos/pinkflamingo/lib/data/seed_data.dart','w').write('\n'.join(lines))
print('Wrote seed_data.dart with', len(out), 'products,', len(CATS), 'categories,', len(KITS), 'kits')
