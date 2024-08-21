const url = "http://cip.cc";

$httpClient.get({
  url: url,
  headers: {
    "User-Agent": "curl/7.64.1"
  }
}, function(error, response, data) {
  if (error) {
    $done({
      title: "IP 信息",
      content: "获取失败，请检查网络",
      icon: "xmark.circle",
      "icon-color": "#FF0000"
    });
  } else {
    // 分割响应数据为行
    const lines = data.split('\n');
    // 只取前三行
    const relevantInfo = lines.slice(0, 3).join('\n');
    
    $done({
      title: "IP 信息",
      content: relevantInfo,
      icon: "network",
      "icon-color": "#007AFF"
    });
  }
});