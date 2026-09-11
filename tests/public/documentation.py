#!/usr/bin/env python3
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
import json,re,collections
r=Path(__file__).resolve().parents[2];broken=[];total=0
class Links(HTMLParser):
 def __init__(self):super().__init__();self.links=[]
 def handle_starttag(self,tag,attrs):
  for k,v in attrs:
   if k in ('href','src') and v:self.links.append(v)
for p in sorted(r.rglob('*')):
 if not p.is_file() or p.is_relative_to(r/'build') or p.suffix not in {'.md','.html'}:continue
 text=p.read_text()
 if p.suffix=='.md':
  text=re.sub(r'(?ms)^(`{3,}|~{3,})[^\n]*\n.*?^\1\s*$','',text)
  links=re.findall(r'(?<!!)\[[^\]\n]*\]\(([^\s)]*)(?:\s+"[^\n]*")?\)',text)
 else:
  parser=Links();parser.feed(text);links=parser.links
 for target in links:
  parts=urlsplit(target)
  if parts.scheme or parts.netloc or not parts.path:continue
  path=p.parent/unquote(parts.path);total+=1
  if not path.exists():broken.append(dict(path=p.relative_to(r).as_posix(),target=target))
assert not broken,broken[:30]
# Re-render in memory to verify all published reference bytes and provenance pins.
import importlib.util,hashlib
spec=importlib.util.spec_from_file_location('public_doc_factory',r/'scripts/rf204/doc_factory.py')
factory=importlib.util.module_from_spec(spec);spec.loader.exec_module(factory)
corpora=collections.defaultdict(list)
for p in (r/'docs/public').rglob('*.json'):
 if not p.is_file():continue
 try:d=json.loads(p.read_bytes())
 except ValueError:continue
 if isinstance(d,dict) and {'identity','slug','provenance','sections'}<=d.keys():corpora[p.parent].append(d)
for directory,documents in sorted(corpora.items()):
 manifest=json.loads((directory/'manifest.json').read_bytes())
 title=re.search(r'<title>(.*?)</title>',(directory/'index.html').read_text()).group(1)
 outputs=factory.reference_files(r,documents,title=title,profile=manifest['profile'],max_documents=1024)
 for name,raw in outputs.items():assert (directory/name).read_bytes()==raw,('reference drift',str(directory/name))
print(json.dumps(dict(status='PASS',local_links=total,broken_links=0,reference_corpora=len(corpora),reference_documents=sum(map(len,corpora.values())))))
