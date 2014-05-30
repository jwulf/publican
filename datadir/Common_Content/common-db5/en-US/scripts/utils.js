function pop(entity) {
    if(entity) {
        var my_parent = entity.parentNode;
        var my_class = my_parent.className;
        my_parent.className = my_class.replace(/popper/,"popped");
    }
}
function unpop(entity) {
    if(entity) {
        var my_parent = entity.parentNode;
        var my_class = my_parent.className;
        my_parent.className = my_class.replace(/popped/,"popper");
    }
}

function siblings(entity){
    var r = [];
    for ( var n = entity.parentNode.firstChild; n; n = n.nextSibling ) 
       if ( n.nodeType == 1 && n != entity)
          r.push( n );        
    return r;
}

/* This displays an element and hides all it's siblings */
function activateElement(id) {
    var entity = document.getElementById(id);
    if(entity.className.indexOf("active") == -1) {
        entity.className = entity.className + " active";
    }
    var sibs =  siblings(entity);

    for(var i=0; i < sibs.length; i++) {
    if(sibs[i].className.indexOf("active") != -1) {
         sibs[i].className = sibs[i].className.replace(/[ ]*active/, '');
        }
    }
}

function getCookie(name) {
    var name_c = window.location.hostname + '-' + name;

    if(document.cookie) {
        var cookies = document.cookie.split(/ *; */);
        for(var i=0; i < cookies.length; i++) {
            var current_c = cookies[i].split("=");
            if(current_c[0] == name_c) {
                return(current_c[1]);
                break;
            }
        }
    }
    return('');
}

function setCookie(name, value, expires, path) {
    name = window.location.hostname + '-' + name;

    var curCookie = name + "=" + value + 
        ((expires) ? ";expires=" + expires.toGMTString() : "") + 
        ((path) ? ";path=" + path : "");
    document.cookie = curCookie; 
}

function setDefLangCookie(entity) {
    setCookie('switchery', entity.options[entity.selectedIndex].value, '', '/');
}

function initSwitchery() {
    var divs = document.getElementsByTagName('div');
    for(i in divs) {
        if(typeof(divs[i].className) != 'undefined' && divs[i].className.indexOf("switchery") != -1) {
            var lang = getCookie('switchery');
            if(lang != '') {
                var entity = document.getElementById(divs[i].id + '-' + lang);
                if(entity) {
                    entity.onclick();
                    entity.parentNode.lastChild.value = lang;
                } else {
                    divs[i].firstChild.firstChild.onclick();
                }
            } else {
                divs[i].firstChild.firstChild.onclick();
            }
        }
    }

}


