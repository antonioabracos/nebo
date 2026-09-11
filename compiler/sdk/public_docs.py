"""Bounded offline public documentation; document identities are not SymbolIds."""
from __future__ import annotations
import argparse,hashlib,html,io,json,os,re,shutil,stat,tarfile,tempfile
from pathlib import Path,PurePosixPath
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
import posixpath
SCHEMA='nebo.public-docs.v1'
MAX_FILES=20000
MAX_BYTES=128*1024*1024
MAX_FILE=16*1024*1024
MAX_DOCUMENTS=8192
PREFIXES=('language/core','reference/core','reference/prelude','reference/stdlib','reference/domains','diagnostics/core','tutorials','cookbook','examples/projects','troubleshooting')
class DocsError(ValueError):
 code='NEBO_PUBLIC_DOCS_REJECTED'
def need(v,message):
 if not v:raise DocsError(message)
def blob(v):return (json.dumps(v,ensure_ascii=False,sort_keys=True,separators=(',',':'))+'\n').encode()
def sha(v):return hashlib.sha256(v).hexdigest()
def relative(name):
 need(isinstance(name,str) and name and not any(ord(c)<32 or c in ':?#%\\' for c in name),'unsafe relative path')
 p=PurePosixPath(name);need(p.parts and not p.is_absolute() and '..' not in p.parts and p.as_posix()==name,'unsafe relative path');return p
def read(path):
 need(not path.is_symlink() and path.is_file() and path.stat().st_size<=MAX_FILE,'input must be a bounded regular file');return path.read_bytes()
def read_tree(root):
 need(root.is_dir() and not root.is_symlink(),'root must be a real directory');out={};size=0
 for base,dirs,names in os.walk(root,followlinks=False):
  need(all(not (Path(base)/d).is_symlink() for d in dirs),'linked directory')
  for n in sorted(names):
   p=Path(base)/n;data=read(p);size+=len(data);out[p.relative_to(root).as_posix()]=data;need(len(out)<=MAX_FILES and size<=MAX_BYTES,'corpus budget')
 return out
def index_rows(files):
 rows=[];seen=set()
 for name,data in sorted(files.items()):
  if not name.endswith('.json') or name.endswith(('manifest.json','search-index.json')):continue
  obj=json.loads(data)
  if not isinstance(obj,dict) or 'identity' not in obj or 'title' not in obj:continue
  page=name[:-5]+'.html'
  if page not in files:continue
  identity=name[:-5]+':'+obj['identity'];need(identity not in seen,'duplicate document identity');seen.add(identity)
  rows.append(dict(id=identity,title=obj['title'],summary=obj.get('summary',''),module=name.split('/')[0],path=page,availability=obj.get('availability','DOCUMENTATION_ONLY'),target=obj.get('target','OFFLINE_LOCAL')))
 need(0<len(rows)<=MAX_DOCUMENTS,'document budget');return rows
def search(index,query,limit=20):
 need(index.get('schema')==SCHEMA and type(limit)is int and 1<=limit<=256,'search schema or limit');need(isinstance(query,str) and 0<len(query)<=256,'query budget')
 terms=query.lower().split();need(terms,'empty query');rows=index.get('documents');need(isinstance(rows,list) and len(rows)<=MAX_DOCUMENTS,'search document budget');rank=[]
 for r in rows:
  need(set(r)=={'id','title','summary','module','path','availability','target'} and all(isinstance(v,str) for v in r.values()),'search row schema');relative(r['path'])
  title=r['title'].lower();text=' '.join([title,r['summary'].lower(),r['id'].lower(),r['module'].lower()])
  if all(t in text for t in terms):rank.append((-sum(100 if title==t else 50 if title.startswith(t) else 10 for t in terms),r['id'],r))
 return [r for _,_,r in sorted(rank,key=lambda x:(x[0],x[1]))[:limit]]
STYLE=b'body{font:18px/1.55 system-ui,sans-serif;max-width:78rem;margin:2rem auto;padding:0 1.5rem;color:#182537;background:#fff}a{color:#164da0}a:focus-visible,input:focus-visible,button:focus-visible{outline:3px solid #bd4700;outline-offset:3px}input,button{font:inherit;padding:.4rem}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f1f4f8;padding:1rem}nav ul{display:flex;gap:.75rem 1.5rem;flex-wrap:wrap;list-style:none;padding:0}nav li{margin:0}label{display:block;margin-bottom:.5rem}input{margin-right:.5rem}li{margin:.5rem 0}.skip{display:inline-block}code{font-size:.92em}aside{border-left:4px solid #31547c;padding:1rem}small{display:block;color:#35465d}'
SCRIPT=b'''"use strict";
function searchDocs(index,query,limit=20){const terms=query.toLowerCase().trim().split(/\\s+/).filter(Boolean);if(!terms.length||query.length>256)return [];return index.documents.map(r=>{const title=r.title.toLowerCase(),text=[title,r.summary.toLowerCase(),r.id.toLowerCase(),r.module.toLowerCase()].join(" ");return {r,score:terms.every(t=>text.includes(t))?terms.reduce((s,t)=>s+(title===t?100:title.startsWith(t)?50:10),0):-1};}).filter(x=>x.score>=0).sort((a,b)=>b.score-a.score||(a.r.id<b.r.id?-1:a.r.id>b.r.id?1:0)).slice(0,limit).map(x=>x.r);}
if(typeof module!=="undefined")module.exports=searchDocs;
if(typeof document!=="undefined"){const input=document.getElementById("query"),list=document.getElementById("results"),status=document.getElementById("status");function update(){const rows=searchDocs(window.NEBO_PUBLIC_INDEX,input.value);list.replaceChildren();for(const r of rows){const li=document.createElement("li"),a=document.createElement("a"),small=document.createElement("small");a.href=r.path;a.textContent=r.title;small.textContent=r.availability+" / "+r.target;li.append(a,small);list.append(li);}status.textContent=rows.length+" results (up to 20 shown)";}document.getElementById("search").addEventListener("submit",e=>{e.preventDefault();update();});input.addEventListener("input",update);}
'''
def assemble(source):
 need(source.is_dir() and not source.is_symlink(),'source root')
 files={}
 for prefix in PREFIXES:
  need(all(not (source/Path(*PurePosixPath(prefix).parts[:i])).is_symlink() for i in range(1,len(PurePosixPath(prefix).parts)+1)),'linked source ancestor')
  for name,data in read_tree(source/prefix).items():files[prefix+'/'+name]=data
 rows=index_rows(files);index=dict(schema=SCHEMA,documents=rows);files['search-index.json']=blob(index)
 files['assets/search.js']=SCRIPT;files['assets/index.js']=b'window.NEBO_PUBLIC_INDEX='+blob(index).rstrip().replace(b'<',b'\\u003c').replace(b'\xe2\x80\xa8',b'\\u2028').replace(b'\xe2\x80\xa9',b'\\u2029')+b';\n';files['assets/style.css']=STYLE
 links=[('tutorials/getting-started.html','Getting started'),('tutorials/language-tour-edition-1.0.html','Language tour'),('cookbook/index.html','Cookbook'),('examples/projects/index.html','Executable projects'),('troubleshooting/index.html','Troubleshooting'),('reference/core/index.html','Core reference'),('reference/stdlib/index.html','Standard Library'),('reference/domains/index.html','Domain packs')]
 body=''.join('<li><a href="'+p+'">'+html.escape(title)+'</a></li>' for p,title in links)
 files['index.html']=('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src \'none\'; script-src \'self\'; style-src \'self\'; img-src \'self\' data:; connect-src \'none\'"><title>Nebo offline learning and reference</title><link rel="stylesheet" href="assets/style.css"><script defer src="assets/index.js"></script><script defer src="assets/search.js"></script></head><body><a class="skip" href="#main">Skip to content</a><main id="main"><h1>Nebo offline learning and reference</h1><p>Learn the current Edition 1 profile, run local projects and inspect each API’s maturity and target. All pages and search data are local.</p><nav aria-label="Learning and reference"><ul>'+body+'</ul></nav><form id="search" role="search"><label for="query">Search titles, identities and summaries</label><input id="query" name="query" type="search" maxlength="256"><button type="submit">Search</button></form><p id="status" role="status" aria-live="polite">Enter a query. Keyboard users can Tab through results and open them with Enter.</p><ul id="results"></ul><noscript><p>JavaScript search is unavailable. Use the navigation and each reference’s complete index with Browser Find.</p></noscript><p><a href="man/nebo-docs.1">CLI manual</a> / <a href="completion-metadata.json">Editor help metadata</a></p></main></body></html>\n').encode()
 files['completion-metadata.json']=blob(dict(schema=SCHEMA,commands=['docs portal build','docs portal verify','docs portal restore','docs search'],help=[dict(label=r['title'],document=r['path'],identity=r['id']) for r in rows]))
 files['man/nebo-docs.1']=b'.TH NEBO-DOCS 1\n.SH NAME\nneboc docs \\- offline public reference and source documentation\n.SH SYNOPSIS\nneboc docs portal build PUBLIC_ROOT -o OUTPUT [--archive FILE]\n.br\nneboc docs portal verify OUTPUT\n.br\nneboc docs portal restore ARCHIVE -o OUTPUT\n.br\nneboc docs search QUERY --index OUTPUT/search-index.json [--limit 1..256] [--report json]\n.SH DESCRIPTION\nPublic-document identities are distinct from serialized language SymbolIds. All operations are local. Build and restore reject occupied outputs and links. Search ranks title matches, then orders by document identity. The archive has deterministic names, modes, ownership and timestamps.\n.SH LIMITS\n8192 documents; 20000 files; 16 MiB per file; 128 MiB corpus; 256 query characters.\n.SH DIAGNOSTICS\nNEBO_PUBLIC_DOCS_REJECTED identifies a malformed, missing, unsafe or over-budget input. No network access is needed.\n'
 files['MANIFEST.json']=blob(dict(schema=SCHEMA,documents=len(rows),files={p:dict(sha256=sha(v),bytes=len(v)) for p,v in sorted(files.items())}))
 verify(files);return files

def verify(files):
 need(len(files)<=MAX_FILES and sum(map(len,files.values()))<=MAX_BYTES,'corpus budget')
 need('MANIFEST.json' in files,'missing manifest');manifest=json.loads(files['MANIFEST.json']);need(manifest.get('schema')==SCHEMA,'manifest schema')
 need(manifest['files']=={p:dict(sha256=sha(v),bytes=len(v)) for p,v in sorted(files.items()) if p!='MANIFEST.json'},'manifest content mismatch')
 for name,data in files.items():relative(name);need(len(data)<=MAX_FILE,'file budget')
 index=json.loads(files['search-index.json']);need(index.get('schema')==SCHEMA and len(index['documents'])==manifest['documents'],'index mismatch')
 need(index['documents']==index_rows(files),'search parity')
 for r in index['documents']:need(r['path'] in files,'unresolved search result')
 need(files['assets/search.js']==SCRIPT and files['assets/style.css']==STYLE,'active asset drift')
 expected=b'window.NEBO_PUBLIC_INDEX='+blob(index).rstrip().replace(b'<',b'\\u003c').replace(b'\xe2\x80\xa8',b'\\u2028').replace(b'\xe2\x80\xa9',b'\\u2029')+b';\n'
 need(files['assets/index.js']==expected,'browser index drift')
 pages={}
 class Page(HTMLParser):
  def __init__(self,name):super().__init__();self.name=name;self.ids=set();self.links=[]
  def handle_starttag(self,tag,attrs):
   need(len(dict(attrs))==len(attrs),'duplicate HTML attribute')
   attrs=dict(attrs);need(not any(k.startswith('on') for k in attrs),'active HTML attribute')
   need(tag in {'html','head','body','title','meta','link','script','main','nav','aside','h1','h2','h3','h4','h5','h6','p','a','ul','ol','li','pre','code','strong','em','small','span','table','thead','tbody','tr','th','td','br','hr','form','label','input','button','noscript','img','figure','figcaption'},'unsupported HTML element')
   need(all(k in {'id','class','lang','href','src','rel','charset','name','content','http-equiv','defer','role','for','type','maxlength','alt','width','height','scope','colspan','rowspan'} or k.startswith('aria-') for k in attrs),'unsupported HTML attribute')
   need(tag not in {'iframe','object','embed','base','style'},'active HTML element')
   need('style' not in attrs and not (tag=='meta' and attrs.get('http-equiv','').lower()=='refresh'),'active HTML style or redirect')
   if tag=='script':need(self.name=='index.html' and attrs.get('src') in {'assets/search.js','assets/index.js'},'untrusted script')
   if 'id' in attrs:need(attrs['id'] not in self.ids,'duplicate anchor');self.ids.add(attrs['id'])
   if tag=='img':need('alt' in attrs,'image lacks alternate text')
   for key in ('href','src'):
    if key in attrs:self.links.append(attrs[key])
 for name,data in files.items():
  if name.endswith('.html'):page=Page(name);page.feed(data.decode());pages[name]=page
 for name,page in pages.items():
  for link in page.links:
   parts=urlsplit(link);need(not parts.scheme and not parts.netloc and not parts.path.startswith('/'),'external dependency')
   path=posixpath.normpath(posixpath.join(posixpath.dirname(name),unquote(parts.path))) if parts.path else name
   need(path in files,'broken link: '+name+' -> '+path)
   if parts.fragment:need(path in pages and unquote(parts.fragment) in pages[path].ids,'broken fragment')
 return manifest

def publish(files,output):
 need(not output.exists() and not output.is_symlink(),'destination exists');need(output.parent.is_dir() and not output.parent.is_symlink(),'output parent')
 stage=Path(tempfile.mkdtemp(prefix='.nebo-public-docs-',dir=output.parent))
 try:
  for name,data in sorted(files.items()):p=stage/relative(name);p.parent.mkdir(exist_ok=True,parents=True);p.write_bytes(data);p.chmod(0o644)
  verify(read_tree(stage));os.replace(stage,output)
 finally:
  if stage.exists():shutil.rmtree(stage)
def archive(files,path):
 verify(files);need(not path.exists() and not path.is_symlink(),'archive destination exists');need(path.parent.is_dir() and not path.parent.is_symlink(),'archive parent')
 fd,tmp=tempfile.mkstemp(prefix='.nebo-public-archive-',dir=path.parent);os.close(fd)
 try:
  with tarfile.open(tmp,'w',format=tarfile.USTAR_FORMAT) as out:
   for name,data in sorted(files.items()):
    info=tarfile.TarInfo(name);info.size=len(data);info.mode=0o644;info.mtime=0;info.uid=info.gid=0;out.addfile(info,io.BytesIO(data))
  need(Path(tmp).stat().st_size<=MAX_BYTES+MAX_FILES*1024,'archive budget');os.replace(tmp,path)
 finally:
  if Path(tmp).exists():Path(tmp).unlink()
 return sha(path.read_bytes())
def restore(path,output):
 need(not path.is_symlink() and path.is_file() and path.stat().st_size<=MAX_BYTES+MAX_FILES*1024,'archive input');files={};size=0
 with tarfile.open(path,'r:') as archive:
  for member in archive:
   relative(member.name);need(member.isfile() and member.name not in files and member.mode==0o644 and 0<=member.size<=MAX_FILE,'unsafe archive member');size+=member.size;need(len(files)<MAX_FILES and size<=MAX_BYTES,'archive budget');files[member.name]=archive.extractfile(member).read()
 verify(files);publish(files,output);return len(files)
def _main(argv):
 p=argparse.ArgumentParser(prog='neboc docs portal');sub=p.add_subparsers(dest='command',required=True)
 b=sub.add_parser('build');b.add_argument('source',type=Path);b.add_argument('-o','--output',type=Path,required=True);b.add_argument('--archive',type=Path)
 v=sub.add_parser('verify');v.add_argument('root',type=Path)
 r=sub.add_parser('restore');r.add_argument('archive',type=Path);r.add_argument('-o','--output',type=Path,required=True)
 a=p.parse_args(argv)
 if a.command=='build':
  files=assemble(a.source);need(not a.output.exists(),'destination exists')
  if a.archive:need(not a.archive.exists() and a.archive.absolute()!=a.output.absolute() and not a.archive.absolute().is_relative_to(a.output.absolute()),'archive destination exists or overlaps output')
  digest=archive(files,a.archive) if a.archive else None
  try:publish(files,a.output)
  except BaseException:
   if a.archive:a.archive.unlink()
   raise
  result=dict(command='build',files=len(files),archive_sha256=digest)
 elif a.command=='verify':
  manifest=verify(read_tree(a.root));result=dict(command='verify',files=len(manifest['files']),documents=manifest['documents'])
 else:result=dict(command='restore',files=restore(a.archive,a.output))
 print(json.dumps(dict(schema=SCHEMA,network=False,**result),sort_keys=True));return 0


def main(argv):
 try:return _main(argv)
 except DocsError:raise
 except (OSError,ValueError,TypeError,KeyError,UnicodeError,tarfile.TarError) as error:
  raise DocsError('invalid public documentation input: '+str(error)) from error
