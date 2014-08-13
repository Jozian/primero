_primero.clean_page_params = function(q_param) {
  var source = location.href,
      rtn = source.split("?")[0],
      param,
      params_arr = [],
      query = (source.indexOf("?") !== -1) ? source.split("?")[1] : "";
  if (query !== "") {
      params_arr = query.split("&");
      for (var i = params_arr.length - 1; i >= 0; i -= 1) {
          param = params_arr[i].split("=")[0];
          for(var j = 0; j < q_param.length; j++) {
            if (param === q_param[j]) {
                params_arr.splice(i, 1);
            }
          }
      }
      rtn = params_arr.join("&");
  } else {
    rtn = "";
  }
  return rtn;
};

_primero.get_param = function(param) {
  var query = window.location.search.substring(1);
  var params = query.split("&");
  for (var i=0; i< params.length; i++) {
    var key_val = params[i].split("=");
    if(key_val[0] == param){
      return key_val[1];
    }
  }
  return false;
};

$(document).ready(function() {
});
