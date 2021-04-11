class HelperSrc{
constructor(...Classes){
    let _=this
    _.log={}    
    if(!window.started)window.started=+new Date()
    if(!window.txt) window.txt={}
    if(!window.log) {
        window.log = function(){/*console.trace();*/console.log(...arguments);return true}
        window.l=function(){
            if(!_.logId) _.logId=''
            if(!_.log[_.logId])_.log[_.logId]=[]        
            _.log[_.logId].push([...arguments])
            _.store('log',_.log)
            window.log(...arguments)    
        }
    }
    window.screen = function(){
        let args=[]
        for(let a of arguments) args.push(a)
        _.$screen&&_.$screen.rm()
        if(!_.$screen)_.$screen=_.$({},'screen').to(_.$body)
        _.ech(args,a=> _.$screen.html(_.$screen.html()+`<div>${a}</div>`) )
        _.screenRmTo=null
        _.screenRmTo=setTimeout(()=>{
            _.$screen.rm()
            _.$screen=null    
        },5000)
    }
    window.fromStart=function(name='',l=0){
        let r=(+new Date()-window.started)/1000
        l&&log(name,r,'sec')
        return r 
    }
    _.traceComs=['to','_to']
    if(!window.tracing)window.tracing=[]
    if(!window.uid)window.uid=1
    _.axRespParse=false
    _.smallScreen = _.sS = window.outerWidth<640?true:false    
    _.$html = _.$(document.getElementsByTagName('html')[0])
    _.$body = _.$(document.getElementsByTagName('body')[0])
    _.$head = _.$(document.getElementsByTagName('head')[0])
    _.touchscreen=_.isTouch()
    Classes.forEach(Class=>{
        class Exemplar extends Class{constructor(...args) {super(...args)}}
        let obj = new Exemplar()                
        _.copyProps(_.__proto__, obj.__proto__)
        _.copyProps(_, obj)    
    })
    let search=location.search,gets={}
    //try{history.pushState(null,'',location.pathname)}catch(er){}
    search.replace(new RegExp( "([^?=&]+)(=([^&]*))?", "g" ), ( $0, $1, $2, $3 )=>gets[$1] = $3)
    localStorage.gets = JSON.stringify(gets)
    window.gets=gets                      
}                       
get winHeight(){
    return this.sS?window.outerHeight:window.innerHeight
}
get winWidth(){
    return this.sS?window.outerWidth:window.innerWidth
}
copyProps(target, source){
  Object.getOwnPropertyNames(source)
    .concat(Object.getOwnPropertySymbols(source))
    .forEach((prop) => {
      if (prop.match(/^(?:constructor|__proto__|prototype|arguments|caller|name|bind|call|apply|toString|length)$/)) return
      Object.defineProperty(target, prop, Object.getOwnPropertyDescriptor(source, prop))
  })
}
trace(c,e,t=null){
    if(!(window.Tracebe&&window.Tracebe.pageLoaded))return
    let _=this,i=_.traceComs.indexOf(c),ec,tc,h=0,tr=[c]
    for(let cl of e.classList)if(cl.match(/e[\d]+/))h=cl
    if(h){
        if(['to','_to'].includes(c))tr.push(e.outerHTML)
        else tr.push(h)
    }
    h=0
    if(_.isE(t)){
      for(let cl of t.classList)if(cl.match(/e[\d]+/))h=cl
      if(h)tr.push(h)        
    }
    tr.push(window.fromStart())
    //log(tr)
    window.tracing.push(tr)    
}
$(i,nm='div'){
  if(!i)return null  
  let _=this,ns,df
  if(['svg','defs','circle','polygon','rect','path','line','marker','foreignObject'].indexOf(nm)!=-1 ){ns='NS';df=nm;nm='http://www.w3.org/2000/svg'}
  else{ns='';df=null}
  let e,created=false
  if(_.isE(i))e=i
  else if(typeof i=='string'&&i[0]!='+') {
    let a
    a=document.querySelectorAll(i)
    if(a.length>1){
        e=[]
        a.forEach(b=>e.push(_.$(b)))
        return e    
    }else e = a[0]
  } else {
    if(i[0]=='+') nm=i.substring(1)
    e=document['createElement'+ns](nm,df)
    created=true    
    if(typeof i!='string')for(let n in i){
        let n_=n=='cl'?'className':n;
        try{e[n_]=i[n]}catch(er){}
    }
  }
  
  if(!e) return null
  e.$self=e
  e.$_=e
  e.$=e
  try{!e[0]&&(e[0]=e)} catch(er){}
  if(!e.uid){
    e.uid=window.uid
    window.uid++
  }
  /*
  if(created)e.classList.add('e'+e.uid)
  else{
    let has=false
    for(let c of e.classList)if(c.match(/e[\d]+/))has=true
    if(!has)e.classList.add('e'+e.uid)
  }
  */
  e.to=to=>{
    _.trace('to',e,to)
    to.appendChild(e)
    return e
  }
  e._to=to=>{
    _.trace('_to',e,to)
    to.prepend(e);return e
  }
  e.styles=styles=>{e.setAttribute('style', styles);return e}
  e.copyAttr=f=>{
    for (let i = 0; i < f.attributes.length; i++) {
        let a = f.attributes[i]
        e.attr(a.name, a.value)
    }    
  }
  e.clone=(except=[],toCopy=[])=> {
    let $c
        $c=_.$({},e.localName)
        $c.copyAttr(e)
        $c.html(e.html())        
        $c.css(e.css())
        $c.id=$c.id.replace(/\d+/,m=>+m+1)

    let copy=($c,e)=>{
        for(let n in e) { 
          if(n!='style'&&(typeof e[n]=='function' || n=='d' || _.isE(e[n]) || typeof e[n]=='object') && except.indexOf(n)==-1){
            try{
                if(_.isE(e[n])) {                   
                      $c[n]=_.$({},e[n].localName)
                      $c[n].copyAttr(e[n])
                      $c[n].html(e[n].html())
                      $c[n].css(e[n].css())
                } else {
                  $c[n]=e[n]
                }
            } catch(er){}
          }}
          _.foreach($c.chi(),($chi,i)=>{
              let $clo=$chi.clone(except,toCopy)
              _.$($c.children[i]).rto($clo)
          })
    }
    copy($c,e)
    return $c
  }
  e.rto=(to)=> e.prnt().replaceChild(to, e)
  e.txt=txt=>{
    if(txt===void 0) return e.innerText || e.textContent
    e.innerHTML='';e.appendChild(document.createTextNode(txt));return e
  }
  e.html=(html,i=0)=>{
    if(html===void 0) return e.innerHTML
    if(html instanceof HTMLElement) i==true?e.html(html.outerHTML):html.to(e)
    else e.innerHTML=html
    return e
  }
  e.css=(obj,v)=>{
    //if(!v&&typeof obj=='string') return e.cssValue(obj)
    let styles=ns?e.getAttributeNS(null,'style'):e.getAttribute('style'),prts=(styles||'').split(';'),css={}
    prts.forEach(p=>{
      let nv=p.split(':'),n=nv[0],v=nv.slice(1).join(':')
      if(n)css[n]=v
    })
    if(obj===void 0) return css
    if(v!==undefined) obj={[obj]:v}
    else if(typeof obj=='string') return css[obj]
    for(let n in obj){
      let n_=n
      if(n=='bg')n='background'
      if(n=='cl')n='color'
      if(n=='bc')n='border-color'
      css[n]=obj[n_]
    }
    prts=[]
    for(let n in css)prts.push(n+':'+css[n])    
    ns?e.setAttributeNS(null,'style',prts.join(';')):e.setAttribute('style',prts.join(';'))
    return e
  }
  e.opc=v=>{e.css({opacity:v,'-ms-filter':'progid:DXImageTransform.Microsoft.Alpha(Opacity='+v*100+')','-moz-opacity':v});return e}
  e.prnt=(cl,sl=0,calcToTop=false)=>{
    let p=e,i=0,toTop=e.offsetTop
    if(sl&&(p.className==cl||p.id==cl||p.nodeName==cl||p.localName==cl||cl===p))return p
    for(;i<100;i++){
      if(!p||p.localName=='html') return null
      //console.log(p,this.$(p.parentNode))
      p=this.$(p.parentNode)
      if(!p)return null     
      if(p.hcl(cl)||p.id==cl||p.nodeName==cl||p.localName==cl||!cl||cl===p){
        if(calcToTop) return toTop
        else return this.$(p)
      }
      toTop+=p.offsetTop
      if(!p)return document
    }
  }
  e.scrollToMe=$prnt=> $prnt.scrollTop=e.prnt($prnt,0,true)
  e.rmv=()=>{
    if(e.parentNode){
        e.parentNode.removeChild(e)
        if(e.rmvEvent) e.rmvEvent(e)
    }
  }
  e._={
    get w(){return e.clientWidth},
    get h(){return e.clientHeight},
    get l(){return e.offsetLeft},
    get t(){return e.offsetTop},
    get sl(){return e.scrollLeft},
    set sl(v){e.scrollLeft=v}
  }
  e.th=(withoutP,withM=true)=> {
    let pads=['padding-bottom','padding-top'],margs=['margin-top','margin-bottom'],ph=0,mh=0
    if(withoutP) _.foreach(pads,pad=> ph+= e.cssValue(pad))
    if(withM) _.foreach(margs,marg=> mh+= e.cssValue(marg))
    return e.offsetHeight+mh-ph
  }
  e.cssValue=v=>{
    let r=0
    try {
     r=window.getComputedStyle(e, null).getPropertyValue(v)
    } catch(e) {
     r=e.currentStyle[v]
    }
    r=parseFloat(r||0)
    if(isNaN(r))r=0
    return r      
  }
  e.correctHeight=(ito=null)=>{
    let h=0,margs=['margin-bottom','margin-top'],mh=0,nh=0,withM=true
    _.foreach(margs,marg=> mh+= e.cssValue(marg))
    e.sib($s=>h+=$s.th())
    if(e.prnt()==ito) withM=false
    nh=e.prnt().th(true,withM)-h-mh
    if(nh<0)nh=0    
    e.css({height:nh+'px'})
  }
  e.checkHeight=(to)=>{
      let h=0,withM=true
      e.sib($s=>{
        h+=$s.th()
      })
      if(to==e.prnt()) withM=false
      //console.log(e,'sibHeight=',h,'eHeight=',e.th(),e.prnt(),'parentHeight=',e.prnt().th(true,withM))      
      return h+e.th()>=e.prnt().th(true,withM)?true:false    
  }   
  e.hardHeight=(to,l=0)=>{
    let $p,r,$ch,i=0,ito,iito=to    
    l&&log('initial to IS',to)
    if(typeof to=='string') to=e.prnt(to)
    l&&log('element to IS',to)
    ito=to  
    do{
      //alert(i)
      $p=e  
      for(let x=0;;x++){          
          r=$p.checkHeight(to)
          $ch=$p
          //alert($p.localName+' '+to.localName)
          $p=$p.prnt()
          l&&log($p,to,iito)
          if($p==to) {
              l&&log('found')            
              if(!r) {
                $ch.correctHeight(ito)                
                to=$ch
              }
              //alert('break')
              break
          }
          //screen($p.localName)    
      }
      //alert(to.localName)
      i++
      l&&log('checkHeight',e,to,!e.checkHeight(to))
    }while(e!=to&&i<30)
    //}while(!e.checkHeight(to)&&i<30)
    //alert('end')  
  }
  e.hide=o=> {
    e.prevDisplay=e.cssValue('display')
    o?e.css({visibility:'hidden'}):e.css({display:'none'})
    return e
  }
  e.show=o=> (o?e.css({visibility:'visible'}):e.css({display:e.prevDisplay||''})&&e)  
  e.hcl=cn=>{
    return e.classList.contains(cn)
  }
  e.trigger=nm=>{
    let event
    try{
     event = new Event(nm)
     e.dispatchEvent(event)
    }catch(e){
      event = document.createEventObject()
      event.eventName=nm
      event.eventType=nm
      e.fireEvent("on"+event.eventType,event)     
    }
  }
  e.onClicked=cl=>{
   let p=e
   for(;;){
    if(p.hcl(cl)||p.id==cl) return p    
    if(!(p=p.parentNode)) return null
   }
  }
  if(_.isEmpty(e.d)){
    e.d={}
    e.ds=d=>{e.d_=d}
    e.dg=()=>e.d_
  }
  e.tcl=nm=> e.hcl(nm)?e.rcl(nm):e.acl(nm)
  e.acl=nm=> {e.rcl(nm);e.classList.add(nm);return e}
  e.rcl=nm=> {e.classList.remove(nm);return e}
  e.rm=()=> e&&e.parentNode&&e.parentNode.removeChild(e)
  e.scrollOn=()=>{
      let process=(ev)=>{
        ev.preventDefault()
        e.scrollTop+=(ev.wheelDelta<0?1:-1)*30     
      }
      e.addEventListener('wheel',process)
      e.addEventListener('mousewheel',process)
      e.addEventListener('DOMMouseScroll',process)   
  }
  e.chi=f=> {
    if(_.isE(e.children[f])) return _.$(e.children[f]) 
    let $chi=[]
    _.foreach(e.children, ($ch,i)=>{
      $ch=_.$($ch)
      $ch.d.i=i
      $chi.push($ch)
      if(!isNaN(i)&&f) f($ch,i)
    },true)
    return $chi
  }
  e.sib=f=>{
	let $chi=[],$sib=[] 
    _.$(e.parentNode).chi($ch=> $chi.push($ch))
    _.foreach($chi,($ch,i)=>{
        i=+i
        $ch=_.$($ch)
        if($ch!==e){
            if(typeof f!='string'||typeof f=='string'&&$ch.localName==f)$sib.push($ch)
            if(f&&typeof f==='function'&&!isNaN(i)&&$ch.nodeType===1) f($ch,i)
        }    
    })
    if(typeof f==='number') return $sib[f]  
    return $sib
  }
  e.marginHeight=()=> e.offsetHeight+e.cssValue('margin-top')+e.cssValue('margin-bottom')
  e.marginWidth=()=> e.offsetWidth+e.cssValue('margin-left')+e.cssValue('margin-right')
  e.scrollBottom=()=> e.scrollTop=e.scrollHeight+e.offsetHeight 
  e.attr=(g,s=undefined)=>{
   if((s===undefined||s===true)&&typeof g!='object') {
    let a=e.getAttribute(g)
    if(s===true){
        if(_.isInt(parseInt(a))) a=parseInt(a)
        else if(_.isFloat(parseFloat(a))) a=parseFloat(a)
    }
    return a
   } else {
    if(s!==undefined&&s!==true) g = {[g]:s}
    for(let n in g)/*ns?e.setAttributeNS(null,n,g[n]):*/e.setAttribute(n,g[n])
   } 
   return e
  }
  e.is=i=> e===i
  e.nx=()=> _.$(e.nextSibling)
  e.pr=()=> _.$(e.previousSibling)
  e.bf=t=> {t.parentNode.insertBefore(e,t);return e}
  e.af=t=> {t.parentNode.insertBefore(e, t.nextSibling);return e}
  e.indx = ()=>{
    let i=0,ch=e
    while((ch = ch.previousSibling)!=null) i++
    return i   
  }
  e.mto=to=>{
   let f = document.createDocumentFragment()
   f.appendChild(e)
   to.appendChild(f)
  }
  e.cto=to=>{
   _.htmlToElement(e.outerHTML).to(to)
  }
  e.pto=to=>{
   let f = document.createDocumentFragment()
   f.appendChild(e)
   to.prepend(f)
  }
  e.find=w=> {
    let r=e.querySelectorAll(w),a
    if(!r[0]) return null
    else if(r.length==1) return _.$(r[0])
    else {
     a=[]
     _.foreach(r,$e=> a.push( _.$($e) ),true)
    }
    return a
  }
  e.fch=()=> _.$(e.children[0])
  e.lch=()=> _.$(e.children[e.children.length-1])   
  e.noselect=()=>{
    e.onselectstart = ()=> false
    e.unselectable = "on"
    e.css({'-moz-user-select':'none','-webkit-user-select':'none','-webkit-tap-highlight-color':'rgba(0,0,0,0)','-webkit-touch-callout':'none','user-select':'none','-ms-user-select':'none'})
    return e
  } 
  e.ev=(n,f,filter=()=>true)=>{
    let _=this,parts    
    if((parts=n.split(' '))[1]) _.ech(parts,n=> {
        e.removeEventListener(n,ev=> filter()&&f&&f(ev,e))
        e.addEventListener(n,ev=> filter()&&f&&f(ev,e))
    })
    else {
        e.removeEventListener(n,ev=> filter()&&f&&f(ev,e))
        e.addEventListener(n,ev=> filter()&&f&&f(ev,e) )
    }
  }
  e.replaceItself=()=>{
      const r = _.$({},e.localName)
      for (let i = 0; i < e.attributes.length; i++) {
         const attr = e.attributes[i]
         r.attr(attr.name, attr.value)
      }
      r.innerHTML = e.innerHTML
      e.replaceWith(r)
      return r
  }  
  e.ani=(d,f=()=>{})=>{
    let ini={},afunc=!_.isEmpty(d.css)?'css':'attr',suf=d.suf||''
    d.attr=d.attr||d.css||{}
    _.foreach(d.attr,(v,n)=>ini[n]=afunc=='attr'?e.attr(n,true):e.cssValue(n))
    //log(ini,d.attr)
    //log(afunc)
    d.f=0,d.t=1
    _.ani(d,_d=>{
        _d.cur={}        
        _.foreach(d.attr,(v,n)=> {
            let val=ini[n]+(v-ini[n])*_d.c
            e[afunc](n, val+suf )
            //log(d.w,d.k,n,ini[n]+(v-ini[n])*_d.c+suf)        
            _d.cur[n]=val    
        })
        f(_d)    
    })
  } 
  e.setInputFilter=f=>{
    e.sifF=f
    ;["input", "keydown", "keyup", "mousedown", "mouseup", "select", "contextmenu", "drop"].forEach(event=>{
      let process=function(e) {
        let $i=_.$(this),v=$i.value,max=$i.attr('max',true),min=$i.attr('min',true),sucs=$i.sifF(v),parts=v.match(/\d+(\.\d+)?|(\D+)/gm),max_
        if(v==$i.ov) return
        if(sucs) _.foreach(parts,(p,i)=>{
            if(!isNaN(+p)){
              max_=max
              if($i.attr('name')=='daytime'&&parts[i-1]!=':') max_=23
              if(max_!==null&&+p>max_) {
                  sucs=false
                  if($i.ov==v) $i.ov=max_
              }else
              if(min!==null&&+p<min) {
                  sucs=false
                  if($i.ov==v) $i.ov=min
              }else
              if(max_!==null||min!==null){
                  
              }                 
            }    
        },true)
        if(!v) sucs=true
        if(sucs) {          
          $i.ov = $i.value
          $i.oss = $i.selectionStart
          $i.ose = $i.selectionEnd
        } else if($i.ov) {
          $i.value = $i.ov
          $i.setSelectionRange($i.oss, $i.ose)
        } else {
          $i.value = ''
        }
      }
      e.removeEventListener(event,process)
      e.addEventListener(event,process)
    })
  }
  e.setInfo=(attr)=>{
    let size=attr.size,s=Math.round(size*0.7),d=Math.ceil((size-s)/2),css
    s+='px'
    attr.background=attr.bg||attr.background||'#DDD'
    attr.color=attr.col||attr.color||'#666'
    css={cursor:'pointer',position:'absolute','margin-left':-size+d+'px','margin-top':d+'px','text-align':'center',height:s,width:s,'font-size':s,'line-height':s,'border-radius':'50%',...attr}
    if(attr.right!==void 0)css.right=attr.right
    e.$info=_.$({},'info').css(css).html('?').to(e.prnt())
    return e
  }
  e.Classes={}
  e.implement= async function(name,path){
    let args = [], imports = await import(path)
    for(let i in arguments) if(+i>1) args.push(arguments[i])        
    for(let mod in imports){
        e[name] = new imports[mod](e,...args)
        e[mod]=function(){ return new imports[mod](e,...arguments) } 
    }
    return e  
  }
  e.hoverOpacityChange=()=>{
    let w='hoc',k=_.randString()
    e.hov( ()=> _.ani({w,k,f:0.5,t:1,p:0.2},d=> e.css('opacity',d.c.toFixed(3))), ()=> _.ani({w,k,f:1,t:0.5,p:0.2},d=> e.css('opacity',d.c.toFixed(3))) )
    //e.ev('mouseenter',)
    //e.ev('mouseleave',)
  }
  e.hasMoreText=(I,cnt)=>{
    I.bubble({style:'hover',type:'info2',$c:e,orient:'d',cnt,maxWidth:300,delay:1})
    e.css({position:'relative'})
    _.$({},'veil').css({position:'absolute',top:0,left:0,width:'100%',height:'100%',background: 'linear-gradient(to top, rgba(255,255,255,1) 0%, rgba(255,255,255,0) 50%)'}).to(e)    
  }
  e.hov=(f1,f2=()=>{})=>{
    e.ev('mouseenter',ev=>f1(ev,e))
    e.ev('mouseleave',ev=>f2(ev,e))
  }
  e.trigger=type=>{
   let event
   if ('createEvent' in document) {
        event = document.createEvent('HTMLEvents')
        event.initEvent(type, false, true)
        e.dispatchEvent(event)
    } else {
        event = document.createEventObject();
        event.eventType = type
        e.fireEvent('on'+event.eventType, event)
    } 
  }
  e.bufferOnClick=()=>{
    e.ev('click',()=>{
      if (document.body.createTextRange) {
          const range = document.body.createTextRange()
          range.moveToElementText(e)
          range.select()
      } else if(window.getSelection) {
          const selection = window.getSelection()
          const range = document.createRange()
          range.selectNodeContents(e)
          selection.removeAllRanges()
          selection.addRange(range)
      }
      document.execCommand("copy") 
    })
  }
  e.noSelect=()=> e.css({'-webkit-touch-callout':'none','-webkit-user-select':'none','-ms-user-select':'none','user-select':'none'})
  e.putCounter=(css={})=> {
    e.$counter=_.$('+counter').css(css).to(e)
    if('bottom' in css) e.$counter.bottom=true
  }
  e.counter=c=> {
    c=+c
    if(c>999)c='999+'
    e.$counter.html(c)
    if(c>9&&c<100)e.$counter.acl('m')
    if(c>99&&c<1000)e.$counter.acl('b')
    let gap=-e.$counter.offsetHeight/3+'px',dir=e.$counter.bottom?'bottom':'top'
    e.$counter.css({right:gap,[dir]:gap})   
  }  
  return e
}
ax(){
  return new Promise((tr,fl)=>{
    let ar=arguments,_=this,j=true,rqo,rq_='',h={},drq={}
    if(ar.length==1){
     var a=ar[0],p=a.p,c=a.c||null,m=a.m||'GET',rq=a.rq||'',rt=a.rt||'',ob=a.ob||true
     j=a.j||j 
     h=a.h||{}
     drq=a.drq||{}
    }else var a=ar,p=a[0],c=a[1]||null,m=a[2]||'GET',rq=a[3]||{}
    if(rq instanceof FormData)rq_=rq
    else if(typeof rq=='object'&&ob){
     let ps=[]
     ;(function iter(obj,count) {
       count++  
       for(var key in obj) {
         if (typeof obj[key]==="boolean") obj[key]=+obj[key]
         else if (obj[key]!==null && typeof obj[key]==="object") iter(obj[key],count)
       }
     })(rq,1)     
     //ps=rq.split('&')
     for(let i in rq){
        if(typeof rq[i]=='object'&&!h['Content-type']){
            rq={json:JSON.stringify(rq)}
            break
        }
     }
     rq=Object.assign(rq,drq)
     _.foreach(rq,(v,n)=>{
      ps.push(n+'='+v)      
     })
     rq_=ps.join('&')
     if(!h['Content-type']) h['Content-type']='application/x-www-form-urlencoded'
    } else rq_=rq
    let x=new XMLHttpRequest()
    x.onreadystatechange=function(){
      if(this.readyState==4&&this.status==200){
       let o='response' in x?x.response:x.responseText
       if(j||_.axRespParse){try{o=JSON.parse(o)} catch(e){}}
       if(c) c(o)
       else tr(o)
      } else if(this.readyState==4){
        console.warn(this.status)
      }       
    }    
    if(/\.json$/.test(p)) p+='?'+(+new Date)
    x.open(m,p,true)    
    for(let k in h) x.setRequestHeader(k,h[k])
    if(rt) x.responseType=rt   
    try{x.send(rq_)}catch(e){fl(e)}
  })
}
loadMulti(){
    let _=this,ar=[]
    _.foreach(arguments,a=>ar.push(a))
    ar=ar.slice(0,-1)
    let c=ar.length,ca=arguments[c],t=0,re=[]
    _.foreach(ar,(a,i)=>_.ax(a,o=>{
        re[parseInt(i)]=o
        t++
        if(t==c)ca(re)   
    }))   
}
log(...args){
 console.log(args[1]?args:args[0])
} 
randId(l) {
 let res='',chars='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
 for(let i=0;i<l;i++)res+=chars.charAt(Math.floor(Math.random()*length));
 return res;
}
apHtml(el, str) {
  let div = document.createElement('div')
  div.innerHTML = str
  while(div.children.length > 0) el.appendChild(div.children[0])
}
daytime(t){
    if(!t) return''
    let d = new Date(t),h=d.getHours(),m=d.getMinutes()
    if(h<10) h='0'+h
    if(m<10) m='0'+m
    return h+':'+m
}
async foreach(e,f,isInt=0,awaiting=false){
    let i0=0,r,incr=0
    if(!e) return false
    if(this.isE(e)) e=[e]
    for(let i in e){
        i0=parseInt(i)
        if(!isNaN(i0))i=i0
        if(isInt&&!Number.isInteger(i)) continue
        if(awaiting) r = await f(e[i],i,incr)
        else r = f(e[i],i,incr)
        if(r==='stop') break
        incr++
    }
}
static async ech(e,f,isInt=0,awaiting=false){
    let i0=0,r,incr=0
    if(!e) return false
    if(HelperSrc.isE(e)) e=[e]   
    for(let i in e){
        if(e[i]==Object.prototype.ech||e[i]==Array.prototype.ech||i=='ech')continue
        i0=parseInt(i)
        if(!isNaN(i0))i=i0 
        if(isInt&&!Number.isInteger(i)) continue
        if(awaiting) r = await f(e[i],i,incr)
        else r = f(e[i],i,incr)
        if(r==='stop') break
        incr++
    }
} 
async ech(e,f,isInt=0,awaiting=false){
    await this.foreach(e,f,isInt,awaiting)
}
nodes(s){return document.querySelectorAll(s)}
$nodes(s,c){
 let _=this
 _.foreach(_.nodes(s),($n,i)=>  c(_.$($n),i) ,true) 
}
numberWithCommas(x) {return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")}
urlToDomain(href){return this.$({href},'a').hostname}
ani(d,f){
  let _=this,dte
  _.anis=_.anis||{}
  _.anis[d.w]=_.anis[d.w]||{} 
  _.anis[d.w][d.k]=_.anis[d.w][d.k]||{}
  _.anis[d.w][d.k].d=d
  if(d.stp){
     d.fin?d.fin(d):0
    _.anis[d.w][d.k]={}
    return  
  }
  if(d.f==d.t||!d.p){if(!_.anis[d.w][d.k].id){d.c=d.t;f(d)}return}
  if(!d.stt)d.c=d.f,d.stt=+ new Date(),d.ad=d.ad||1,d.id=_.anis[d.w][d.k].id=+ new Date(),d.stp=0
  f(d)
  dte=+ new Date(),d.ext=dte-d.stt,d.stt=dte,d.s=(d.t-d.f)/(d.p*1000/(d.ext+d.ad)),d.c+=d.s
  if(!d.lt&&(d.c>d.t&&d.s>0||d.c<d.t&&d.s<0)){
    d.c=d.t,d.lt=1
    _.ani(d,f)
    return
  }
  if(_.anis[d.w][d.k].id!=d.id||d.c==d.t||d.c>d.t&&d.s>0||d.c<d.t&&d.s<0){
    if(_.anis[d.w][d.k].id==d.id)_.anis[d.w][d.k]={}
    d.c=d.t
    f(d)
    d.fin?d.fin(d):0
    return
  }
  if(d.log)log(d.w,d.k,d.c)
  setTimeout(()=>_.ani(d,f),d.ad*1)
}
brkAni(w,k){
    let _=this
    _.anis&&_.anis[w]&&_.anis[w][k]&&_.anis[w][k].d&&(_.anis[w][k].d.stp=1)
    return true
}
isE(obj) {
  if(typeof obj!='object'||obj===null) return false  
  if(obj.$self) return true  
  if(obj instanceof HTMLElement) return true
  if(obj.constructor.name=='HTMLBodyElement') return true
  if(obj.constructor.name=='HTMLElement') return true
  if(obj.constructor.name=='HTMLUnknownElement') return true
  if(obj.constructor.name=='HTMLDivElement') return true
  if(obj.constructor.name=='HTMLHtmlElement') return true
  if(obj.constructor.name=='HTMLHeadElement') return true
  else if(obj instanceof SVGElement)  return true
  else return !this.isEmpty(obj) && (typeof obj==="object") && (obj.nodeType===1) && (typeof obj.style === "object") && (typeof obj.ownerDocument ==="object")
}
static isE(obj) {
  if(typeof obj!='object'||obj===null) return false  
  if(obj.$self) return true  
  if(obj instanceof HTMLElement) return true
  if(obj.constructor.name=='HTMLBodyElement') return true
  if(obj.constructor.name=='HTMLElement') return true
  if(obj.constructor.name=='HTMLUnknownElement') return true
  if(obj.constructor.name=='HTMLDivElement') return true
  if(obj.constructor.name=='HTMLHeadElement') return true
  else if(obj instanceof SVGElement)  return true
  else return !HelperSrc.isEmpty(obj) && (typeof obj==="object") && (obj.nodeType===1) && (typeof obj.style === "object") && (typeof obj.ownerDocument ==="object")
}
isEmpty(o) {  
  for(var key in o) if(o.hasOwnProperty(key)) return false
  return true
}
static isEmpty(o) {
  for(var key in o) if(o.hasOwnProperty(key)) return false
  return true
}
isEmpty(o) {
  for(var key in o) if(o.hasOwnProperty(key)) return false
  return true
}
htmlToElement(html) {
 var template = document.createElement('template')
 html = html.trim()
 template.innerHTML = html
 return this.$(template.content.firstChild)
}
async loadScript(url,id=null,callback=null){
    return new Promise((tr,fl)=>{
      let script
      if(!id) id=url.replace(/\/|\./g,'')
      if(this.$('script#'+id)) {
        //log(this.$('script#'+id))
        if(callback) callback()
        else tr()
      } else {
          script=document.createElement("script")          
          script.type = "text/javascript"
          if (script.readyState){
              script.onreadystatechange = function(){
                  if (script.readyState == "loaded" || script.readyState == "complete"){
                      script.id=id
                      script.onreadystatechange = null
                      if(callback) callback()
                      else tr()
                  }
              }
          } else {
              script.onload = function(){
                script.id=id
                if(callback) callback()
                else tr()
              }
          }
          script.src = url
          document.getElementsByTagName("head")[0].appendChild(script)
      }
    })
}
async loadCss(href,id=null,callback=null){
  return new Promise((tr,fl)=>{
    if(!id) id=href.replace(/\/|\./g,'')
    if(!this.$('link#'+id)) {
     this.$({id},'link').attr({rel:'stylesheet',type:'text/css',href,media:'all'}).to(this.$head).onload = e=> {
        if(callback)callback()
        else tr()
     }
    } else tr()
  })
}
childIndex(ch){
  let i=0
  while((ch = ch.previousSibling)!=null) i++
  return i
}
save(n,v){
    localStorage[n]=JSON.stringify(v||{})
}
load(n){
    return JSON.parse(localStorage[n]||null) 
}
isInt(n){
    return Number(n) === n && n % 1 === 0;
}
isFloat(n){
    return Number(n) === n && n % 1 !== 0;
}
randString(){return Math.random().toString(36).substring(7)}
implementCss(css,id=''){
    let _=this    
    //if(_.$('style'+(id&&'#'+id))) return       
    let $s=_.$({id},'style'),cnt='',cntrSel=css.cntrSel||''
    for(let s in css){
        if(s=='cntrSel') continue
        let o=css[s], pairs=[]
        for(let n in o) pairs.push(n+':'+o[n])
        cnt+= cntrSel+' '+s+'{'+pairs.join(';')+'}'
    }
    $s.html(cnt).to(_.$head)    
}
countObjectKeys(obj){
    let count=Object.keys(obj).length       
    for(let k in obj) if(typeof obj[k]=='object'&&Object.keys(obj[k]).length&&this.isE(obj[k])) count+=this.countObjectKeys(obj[k])
    return count
}
sumObjValues(obj) {
  obj=obj||{}  
  return Object.keys(obj).reduce((sum,key)=>sum+parseFloat(obj[key]||0),0);
}
objLastValue(obj){
    obj=obj||{}
    let values= Object.values(obj)
    return values[values.length-1]
}
objLastKey(obj){
    obj=obj||{}
    if(this.isEmpty(obj)) return null
    let keys= Object.keys(obj)
    return keys[keys.length-1]
}
htmlizeText(text){
  return text.replace(/\r\n-/g,'<br>&bull;').replace(/^-/,'&bull;').replace(/\r?\n/g,'<br />').replace(/\/\/([^\s<]+)/g,'<a href="https://$1" target="_blank">$1</a>')
}
sortObjectKeys(o,inv=false){return Object.keys(o).sort(function(a,b){return !inv?o[a]-o[b]:o[b]-o[a]})}
isTouch() {    
  let prefixes=' -webkit- -moz- -o- -ms- '.split(' '), mq=query=>window.matchMedia(query).matches
  if(('ontouchstart' in window)||window.DocumentTouch&&document instanceof DocumentTouch) return true;
  return mq(['(', prefixes.join('touch-enabled),('), 'heartz', ')'].join(''))
}
store(n,o,l){
    localStorage[n]=(typeof o=='object'&&JSON.stringify(o))||(typeof o=='string'&&o)||(typeof o=='number'&&o.toString())
    if(l) log('value stored:',localStorage[n],'| key:',n)
}
restore(n,p=0){
    let o=localStorage[n]
    if(!o)return{}
    return p?o:JSON.parse(o)
}
}
try{
Object.defineProperty(Array.prototype,'ech', {
  value: async function(f,isInt=0,awaiting=false){
      if(this.constructor.name=='Array')isInt=1
      await HelperSrc.ech(this,f,isInt,awaiting)    
  },
  writable: false
})
Object.defineProperty(Object.prototype,'ech', {
  value: Array.prototype.ech,
  writable: false
})
}catch(e){}

navigator.sayswho= (function(){
    var ua= navigator.userAgent, tem, 
    M= ua.match(/(opera|chrome|safari|firefox|msie|trident(?=\/))\/?\s*(\d+)/i) || [];
    if(/trident/i.test(M[1])){
        tem=  /\brv[ :]+(\d+)/g.exec(ua) || [];
        return 'IE '+(tem[1] || '');
    }
    if(M[1]=== 'Chrome'){
        tem= ua.match(/\b(OPR|Edge)\/(\d+)/);
        if(tem!= null) return tem.slice(1).join(' ').replace('OPR', 'Opera');
    }
    M= M[2]? [M[1], M[2]]: [navigator.appName, navigator.appVersion, '-?'];
    if((tem= ua.match(/version\/(\d+)/i))!= null) M.splice(1, 1, tem[1]);
    return M.join(' ');
})();