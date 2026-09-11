#!/usr/bin/env python3
"""Real typed relational values; expected payloads, paths and exits are independent."""
import json
import tempfile
from pathlib import Path
from harness import pipeline, reject, Failure

def cases():
    result=[]
    for owner,constructor in [('tree','Tree<Int>.new(71)'),('node','Node<Int>.new(71)'),
                              ('graph','Graph<Int,Int>.directed()')]:
        for value in (0,7,23,29,255):
            result.append((owner+'-return-'+str(value),constructor+'.a;'+str(value)+'.return;',value,{}))
    for value in (-17,29,71):
        for kind,access in [('Tree','root().value()'),('Node','value()')]:
            result.append((kind+'-payload-'+str(value),f'{kind}<Int>.new({value}).a;a.{access}.console();23.return;',
                           23,{'kinds':[4],'text':str(value).encode()}))
    result += [
        ('node-prefix-existing','Node<Int> 14.node;node.value().return;',14,{}),
        ('node-prefix-changed','Node<Int> 71.node;node.value().return;',71,{}),
        ('node-prefix-expression','Node<Int> (17+29).node;node.value().return;',46,{}),
        ('tree-capacity','Tree<Int>.new(17).t;t.root().r;0.i.mutable;while(i<31){t.addChild(r,i);i+=1;}r.degree().return;',31,{}),
        ('tree-capacity-plus-one','Tree<Int>.new(17).t;t.root().r;0.i.mutable;while(i<32){t.addChild(r,i);i+=1;}23.return;',177,{}),
        ('graph-capacity','Graph<Int,Int>.directed().g;0.i.mutable;while(i<32){g.addNode(i);i+=1;}g.topologicalSort().length().return;',32,{}),
        ('graph-capacity-plus-one','Graph<Int,Int>.directed().g;0.i.mutable;while(i<33){g.addNode(i);i+=1;}23.return;',177,{}),
        ('tree-height-root','Tree<Int>.new(17).t;t.height().return;',1,{}),
        ('tree-height-empty','Tree<Int>.new(17).t;t.removeSubtree(t.root());t.height().return;',0,{}),
        ('tree-child','Tree<Int>.new(17).t;t.addChild(t.root(),71).n;n.value().return;',71,{}),
        ('tree-parent','Tree<Int>.new(17).t;t.addChild(t.root(),71).n;'
         't.parent(n).expect("parent").value().return;',17,{}),
        ('tree-root-parent','Tree<Int>.new(17).t;t.parent(t.root()).isNone().console();23.return;',23,
         {'kinds':[5],'text':b'true'}),
        ('node-replace','Node<Int>.new(17).n;n.replaceValue(71).console();n.value().console();23.return;',23,
         {'kinds':[4,4],'text':b'1771'}),
        ('node-stable-id','Node<Int>.new(17).n;n.id().before;n.replaceValue(71);'
         '(n.id()==before).console();23.return;',23,{'kinds':[5],'text':b'true'}),
        ('tree-degree','Tree<Int>.new(17).t;t.root().r;t.addChild(r,29).a;t.addChild(r,71).b;'
         'r.degree().console();a.degree().console();23.return;',23,{'kinds':[4,4],'text':b'21'}),
        ('tree-two-live','Tree<Int>.new(17).a;Tree<Int>.new(71).b;'
         '(a.root().value()+b.root().value()).return;',88,{}),
        ('tree-foreign-parent','Tree<Int>.new(17).a;Tree<Int>.new(71).b;a.addChild(b.root(),29);23.return;',177,{}),
        ('tree-stale-node','Tree<Int>.new(17).t;t.addChild(t.root(),29).n;t.removeSubtree(n);n.value().return;',177,{}),
        ('tree-stale-slot-reuse','Tree<Int>.new(17).t;t.root().r;t.addChild(r,29).n;t.removeSubtree(n);'
         't.addChild(r,71);n.value().return;',177,{}),
        ('tree-composition','Dict<Int,Int>.new().d;Tree<Int>.new(17).t;List<Int>.from([29]).a;'
         'd.insert(17,71);(t.root().value()+d.get(17).expect("v")+a.at(0)).console();23.return;',23,
         {'kinds':[4],'text':b'117'}),
        ('tree-removed-count','Tree<Int>.new(17).t;t.root().r;t.addChild(r,29).a;t.addChild(a,71);'
         't.removeSubtree(a).return;',2,{}),
        ('tree-lca','Tree<Int>.new(17).t;t.root().r;t.addChild(r,29).a;t.addChild(r,71).b;'
         't.lowestCommonAncestor(a,b).expect("ancestor").value().return;',17,{}),
        ('tree-child-order','Tree<Int>.new(17).t;t.root().r;t.addChild(r,29);t.addChild(r,71);'
         't.children(r).v;v.length().console();v.next().expect("node").value().console();'
         'v.next().expect("node").value().console();v.next().isNone().console();23.return;',23,
         {'kinds':[4,4,4,5],'text':b'22971true'}),
    ]
    for order,values in [('preorder',[17,29,83,71]),('postorder',[83,29,71,17])]:
        body='Tree<Int>.new(17).t;t.root().r;t.addChild(r,29).a;t.addChild(r,71);t.addChild(a,83);'
        body+=f't.{order}().v;'+''.join('v.next().expect("node").value().console();' for _ in values)+'23.return;'
        result.append(('tree-'+order,body,23,{'kinds':[4]*len(values),'text':''.join(map(str,values)).encode()}))
    for directed in (True,False):
        factory='directed' if directed else 'undirected'
        prefix=f'Graph<Int,Int>.{factory}().g;g.addNode(17).a;g.addNode(71).b;g.addEdge(a,b,5).e;'
        result.append(('graph-'+factory+'-neighbors',prefix+'g.neighbors(a).v;v.next().expect("neighbor").value().return;',71,{}))
        result.append(('graph-'+factory+'-reverse',prefix+'g.neighbors(b).v;v.length().return;',0 if directed else 1,{}))
        result.append(('graph-'+factory+'-remove-edge',prefix+'g.removeEdge(e).console();g.neighbors(a).length().console();23.return;',23,
                       {'kinds':[5,4],'text':b'true0'}))
        result.append(('graph-'+factory+'-remove-node',prefix+'g.removeNode(b);g.neighbors(a).length().return;',0,{}))
    result += [
        ('graph-two-live','Graph<Int,Int>.directed().a;Graph<Int,Int>.directed().b;'
         'a.addNode(17).n;b.addNode(71).m;(n.value()+m.value()).return;',88,{}),
        ('graph-foreign-node','Graph<Int,Int>.directed().a;Graph<Int,Int>.directed().b;'
         'a.addNode(17).n;b.addNode(71).m;a.addEdge(n,m,5);23.return;',177,{}),
        ('graph-stale-node','Graph<Int,Int>.directed().g;g.addNode(17).n;g.removeNode(n);n.value().return;',177,{}),
        ('graph-negative-weight','Graph<Int,Int>.directed().g;g.addNode(17).a;g.addNode(71).b;g.addEdge(a,b,-5);23.return;',177,{}),
        ('graph-self-edge','Graph<Int,Int>.directed().g;g.addNode(17).a;g.addEdge(a,a,5);23.return;',177,{}),
        ('graph-duplicate-edge','Graph<Int,Int>.directed().g;g.addNode(17).a;g.addNode(71).b;'
         'g.addEdge(a,b,5);g.addEdge(a,b,7);23.return;',177,{}),
        ('graph-replace','Graph<Int,Int>.directed().g;g.addNode(17).a;a.replaceValue(71).console();'
         'a.value().console();23.return;',23,{'kinds':[4,4],'text':b'1771'}),
        ('graph-degree','Graph<Int,Int>.directed().g;g.addNode(17).a;g.addNode(29).b;g.addNode(71).c;'
         'g.addEdge(a,b,5);g.addEdge(b,c,7);b.degree().return;',2,{}),
    ]
    graph='Graph<Int,Int>.directed().g;g.addNode(17).a;g.addNode(29).b;g.addNode(71).c;g.addNode(83).d;'
    edges='g.addEdge(a,b,5);g.addEdge(a,c,11);g.addEdge(b,d,7);g.addEdge(c,d,3);'
    base=graph+edges
    result += [
        ('graph-acyclic',base+'g.hasCycle().console();23.return;',23,{'kinds':[5],'text':b'false'}),
        ('graph-cycle',base+'g.addEdge(d,a,13);g.hasCycle().console();23.return;',23,{'kinds':[5],'text':b'true'}),
        ('graph-topological',base+'g.topologicalSort().v;'+''.join('v.next().expect("n").value().console();' for _ in range(4))+'23.return;',23,
         {'kinds':[4]*4,'text':b'17297183'}),
        ('graph-topological-cycle',base+'g.addEdge(d,a,13);g.topologicalSort();23.return;',177,{}),
        ('graph-shortest',base+'g.shortestPathUnweighted(a,d).v;'+''.join('v.next().expect("n").value().console();' for _ in range(3))+'23.return;',23,
         {'kinds':[4]*3,'text':b'172983'}),
        ('graph-dijkstra-overflow',graph+'g.addEdge(a,b,9223372036854775807);g.addEdge(b,c,9223372036854775807);g.addEdge(c,d,9223372036854775807);g.dijkstra(a,d);23.return;',177,{}),
        ('graph-unreachable',base+'g.shortestPathUnweighted(d,a).v;v.length().return;',0,{}),
        ('graph-foreign-path',base+'Graph<Int,Int>.directed().other;other.addNode(7).x;g.shortestPathUnweighted(a,x);23.return;',177,{}),
    ]
    components='Graph<Int,Int>.undirected().g;g.addNode(17).a;g.addNode(29).b;g.addNode(71).c;g.addNode(83).d;g.addEdge(a,b,5);g.addEdge(c,d,7);'
    result += [
        ('graph-components-empty','Graph<Int,Int>.undirected().g;g.connectedComponents().p;p.length().return;',0,{}),
        ('graph-components',components+'g.connectedComponents().p;p.length().console();'
         'p.next().expect("component").x;x.next().expect("node").value().console();x.next().expect("node").value().console();'
         'p.next().expect("component").y;y.next().expect("node").value().console();y.next().expect("node").value().console();'
         'p.next().isNone().console();23.return;',23,{'kinds':[4]*5+[5],'text':b'217297183true'}),
        ('graph-components-joined',components+'g.addEdge(b,c,11);g.connectedComponents().p;'
         'p.length().console();p.next().expect("component").x;x.length().console();23.return;',23,
         {'kinds':[4,4],'text':b'14'}),
        ('graph-components-directed',base+'g.connectedComponents();23.return;',177,{}),
        ('graph-components-snapshot',components+'g.connectedComponents().p;g.removeNode(a);'
         'p.next().expect("component").x;x.next().expect("node").value().return;',177,{}),
    ]
    import heapq
    for first,second in [(5,11),(19,2),(31,3)]:
        weights=[(0,1,first),(0,2,second),(1,3,7),(2,3,3)]
        frontier=[(0,0,[0])];best={}
        while frontier:
            cost,node,path=heapq.heappop(frontier)
            if node in best:continue
            best[node]=cost
            if node==3:break
            for left,right,weight in weights:
                if left==node and right not in best:heapq.heappush(frontier,(cost+weight,right,path+[right]))
        values=[17,29,71,83];expected=[values[i] for i in path]
        body=graph+''.join(f'g.addEdge({"abcd"[a]},{"abcd"[b]},{w});' for a,b,w in weights)
        body+='g.dijkstra(a,d).v;'+''.join('v.next().expect("n").value().console();' for _ in path)+'23.return;'
        result.append((f'graph-dijkstra-{first}-{second}',body,23,{'kinds':[4]*len(path),'text':''.join(map(str,expected)).encode()}))
    for method,expected in [('breadthFirst',[17,29,71,83]),('depthFirst',[17,29,83,71])]:
        body=base+f'g.{method}(a).v;'+''.join('v.next().expect("n").value().console();' for _ in expected)
        body+='v.next().isNone().console();v.release();g.addNode(7).n;n.value().console();23.return;'
        result.append(('graph-'+method,body,23,{'kinds':[4]*len(expected)+[5,4],
                       'text':(''.join(map(str,expected))+'true7').encode()}))
    result += [
        ('traversal-scope',base+'if(true){g.breadthFirst(a).v;v.next();}g.addNode(7).n;n.value().return;',7,{}),
        ('traversal-temporary',base+'g.breadthFirst(a).next();g.addNode(7).n;n.value().return;',7,{}),
        ('traversal-break',base+'loop{g.breadthFirst(a).v;v.next();break;}g.addNode(7).n;n.value().return;',7,{}),
        ('traversal-continue',base+'0.i.mutable;while(i<3){g.breadthFirst(a).v;v.next();i+=1;continue;}'
         'g.addNode(7).n;n.value().return;',7,{}),
        ('traversal-return',base+'g.breadthFirst(a).v;v.next().expect("n").value().return;',17,{}),
        ('traversal-bfs-path',base+'g.breadthFirst(a).v;v.next();v.next();v.next();v.next();v.path().p;'
         +''.join('p.next().expect("n").value().console();' for _ in range(3))+'23.return;',23,
         {'kinds':[4]*3,'text':b'172983'}),
        ('traversal-node-mutation',base+'g.breadthFirst(a).v;a.replaceValue(7);23.return;',177,{}),
    ]
    return result

def callback_cases():
    base='Graph<Int,Int>.directed().g;g.addNode(17).a;g.addNode(29).b;g.addNode(71).c;g.addEdge(a,b,5);g.addEdge(b,c,7);'
    result=[]
    for limit,observed in [(20,[17,29]),(50,[17,29,71])]:
        source=f'(Int.self)stop(){{self.console();(self>{limit}).return;}}start(){{'+base
        source+='g.breadthFirst(a).v;v.stopWhen(stop);'+''.join('v.next();' for _ in observed)+'v.next().isNone().console();23.return;}'
        result.append((f'traversal-stop-{limit}',source,23,{'kinds':[4]*len(observed)+[5],
                       'text':(''.join(map(str,observed))+'true').encode()}))
    return result

def negatives():
    return [
        ('traversal-borrow','Graph<Int,Int>.directed().g;g.addNode(17).a;g.breadthFirst(a).v;g.addNode(7);23.return;','NEBO_BORROW_CONFLICT'),
        ('traversal-copy','Graph<Int,Int>.directed().g;g.addNode(17).a;g.breadthFirst(a).v;v.other;23.return;','NEBO_COPY_UNIQUE'),
        ('traversal-released','Graph<Int,Int>.directed().g;g.addNode(17).a;g.breadthFirst(a).v;v.release();v.next();23.return;','NEBO_USE_AFTER_MOVE'),
        ('traversal-bad-predicate','Graph<Int,Int>.directed().g;g.addNode(17).a;g.breadthFirst(a).v;v.stopWhen(true);23.return;','NEBO_TYPE_MISMATCH'),
        *[(f'tree-{method}-arity',f'Tree<Int>.new(17).t;t.{method}(17);23.return;','NEBO_TYPE_MISMATCH')
          for method in ('root','height','preorder','postorder')],
        *[(f'node-{method}-arity',f'Node<Int>.new(17).n;n.{method}(17);23.return;','NEBO_TYPE_MISMATCH')
          for method in ('value','id','degree')],
        *[(f'tree-{method}-node-type',f'Tree<Int>.new(17).t;t.{method}(17);23.return;','NEBO_TYPE_MISMATCH')
          for method in ('parent','children','removeSubtree')],
        ('tree-lca-node-type','Tree<Int>.new(17).t;t.lowestCommonAncestor(t.root(),17);23.return;','NEBO_TYPE_MISMATCH'),
        *[(f'graph-{method}-arity',f'Graph<Int,Int>.directed().g;g.{method}(17);23.return;','NEBO_TYPE_MISMATCH')
          for method in ('hasCycle','topologicalSort','connectedComponents')],
        *[(f'graph-{method}-node-type',f'Graph<Int,Int>.directed().g;g.{method}(17);23.return;','NEBO_TYPE_MISMATCH')
          for method in ('neighbors','removeNode','breadthFirst','depthFirst')],
        ('graph-remove-edge-type','Graph<Int,Int>.directed().g;g.removeEdge(17);23.return;','NEBO_TYPE_MISMATCH'),
        ('graph-add-node-type','Graph<Int,Int>.directed().g;g.addNode(true);23.return;','NEBO_TYPE_MISMATCH'),
        *[(f'graph-{method}-nodes-type',f'Graph<Int,Int>.directed().g;g.{method}(17,29);23.return;','NEBO_TYPE_MISMATCH')
          for method in ('shortestPathUnweighted','dijkstra')],
        ('traversal-path-arity','Graph<Int,Int>.directed().g;g.addNode(17).a;g.breadthFirst(a).v;v.path(17);23.return;','NEBO_TYPE_MISMATCH'),
        ('tree-type','Tree<Text>.new(17).t;23.return;','NEBO_TYPE_MISMATCH'),
        ('tree-payload-type','Tree<Int>.new(true).t;23.return;','NEBO_TYPE_MISMATCH'),
        ('tree-arity','Tree<Int>.new().t;23.return;','NEBO_TYPE_MISMATCH'),
        ('tree-copy','Tree<Int>.new(17).t;t.other;23.return;','NEBO_COPY_UNIQUE'),
        ('tree-raw-handle','Tree<Int>.new(17).t;t.addChild(0,71);23.return;','NEBO_TYPE_MISMATCH'),
        ('tree-wrong-child-value','Tree<Int>.new(17).t;t.addChild(t.root(),true);23.return;','NEBO_TYPE_MISMATCH'),
        ('node-wrong-replacement','Node<Int>.new(17).n;n.replaceValue(true);23.return;','NEBO_TYPE_MISMATCH'),
        ('tree-after-return','Tree<Int>.new(17).t;23.return;t.root();','NEBO_PARSE_UNEXPECTED_TOKEN'),
        ('graph-missing-edge-type','Graph<Int>.directed().g;23.return;','NEBO_TYPE_MISMATCH'),
        ('graph-edge-type','Graph<Int,Text>.directed().g;23.return;','NEBO_TYPE_MISMATCH'),
        ('graph-copy','Graph<Int,Int>.directed().g;g.other;23.return;','NEBO_COPY_UNIQUE'),
        ('graph-raw-handle','Graph<Int,Int>.directed().g;g.addEdge(0,1,5);23.return;','NEBO_TYPE_MISMATCH'),
        ('graph-wrong-weight','Graph<Int,Int>.directed().g;g.addNode(17).a;g.addNode(71).b;'
         'g.addEdge(a,b,true);23.return;','NEBO_TYPE_MISMATCH'),
        ('graph-edge-arity','Graph<Int,Int>.directed().g;g.addNode(17).a;g.addEdge(a,a);23.return;','NEBO_TYPE_MISMATCH'),
    ]

def run():
    results=[]
    with tempfile.TemporaryDirectory(prefix='nebo-G170-relational-',dir='/tmp') as directory:
        root=Path(directory)
        for name,body,expected,options in cases():
            work=root/name;work.mkdir();source=work/'source.no';source.write_text('start(){'+body+'}')
            try:proof=pipeline(source,work,expected,**options)
            except Failure as error:raise Failure(name+': '+str(error)) from error
            results.append(dict(id=name,category='positive',result='PASS',**proof))
        for name,body,expected,options in callback_cases():
            work=root/name;work.mkdir();source=work/'source.no';source.write_text(body)
            try:proof=pipeline(source,work,expected,**options)
            except Failure as error:raise Failure(name+': '+str(error)) from error
            results.append(dict(id=name,category='positive',result='PASS',**proof))
        for name,body,code in negatives():
            work=root/name;work.mkdir();source=work/'source.no';source.write_text('start(){'+body+'}')
            try:proof=reject(source,work,code)
            except Failure as error:raise Failure(name+': '+str(error)) from error
            results.append(dict(id=name,category='negative',result='PASS',**proof))
    return dict(cases=results,passed=len(results),total=len(cases())+len(callback_cases())+len(negatives()))

if __name__=='__main__':print(json.dumps(run(),sort_keys=True))
