<%@ page import="org.apache.catalina.loader.WebappClassLoaderBase" %>
<%@ page import="java.lang.reflect.Field" %>
<%@ page import="org.apache.catalina.WebResourceRoot" %>
<%@ page import="org.apache.catalina.core.StandardContext" %><%--
  Created by IntelliJ IDEA.
  User: Luc
  Date: 2022/12/27
  Time: 9:34
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    WebappClassLoaderBase webappClassLoaderBase =(WebappClassLoaderBase) Thread.currentThread().getContextClassLoader();

    Field field =  WebappClassLoaderBase.class.getDeclaredField("resources");
    field.setAccessible(true);
    WebResourceRoot webResourceRoot = (WebResourceRoot)field.get(webappClassLoaderBase);
    StandardContext standardContext = (StandardContext)webResourceRoot.getContext();

    response.getWriter().write(standardContext.getPath());
%>
<html>
<head>
    <title>Title</title>
</head>
<body>

</body>
</html>
