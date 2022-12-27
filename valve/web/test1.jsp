<%@ page import="java.lang.reflect.Field" %>
<%@ page import="org.apache.catalina.core.ContainerBase" %>
<%@ page import="org.apache.catalina.core.StandardEngine" %>
<%@ page import="org.apache.catalina.core.StandardHost" %>
<%@ page import="org.apache.catalina.core.StandardContext" %>
<%@ page import="org.apache.tomcat.util.net.AbstractEndpoint.Handler" %>
<%@ page import="org.apache.coyote.AbstractProtocol" %>
<%@ page import="org.apache.coyote.RequestInfo" %>
<%@ page import="org.apache.coyote.RequestGroupInfo" %>
<%@ page import="java.util.ArrayList" %><%--
  Created by IntelliJ IDEA.
  User: Luc
  Date: 2022/12/27
  Time: 10:38
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
  String child;
  java.lang.ThreadGroup threadGroup = (java.lang.ThreadGroup)Thread.currentThread().getThreadGroup();
  Field field = threadGroup.getClass().getDeclaredField("threads");
  field.setAccessible(true);
  Thread[] threads = (Thread[])field.get(threadGroup);
  for (Thread thread : threads) {
      if(thread != null && thread.getName().contains("Timeout")){
          Field field1 = thread.getClass().getDeclaredField("target");
          field1.setAccessible(true);
          Runnable target  = (Runnable)field1.get(thread);

          Field field2 = target.getClass().getDeclaredField("this$0");
          field2.setAccessible(true);
          Object handle = field2.get(target);

          Field field3 = AbstractProtocol.class.getDeclaredField("handler");
          field3.setAccessible(true);
          Handler handler = (Handler)field3.get(handle);

          RequestGroupInfo requestGroupInfo = (RequestGroupInfo) handler.getGlobal();

          System.out.println(requestGroupInfo);
          Field field4 = requestGroupInfo.getClass().getDeclaredField("processors");
          field4.setAccessible(true);
          ArrayList<RequestInfo> requestInfo = (ArrayList<RequestInfo>)field4.get(requestGroupInfo);

          RequestInfo requestInfo1 = requestInfo.get(1);
          child = requestInfo1.getCurrentUri().split("/")[1];
          break;
      }
  for(Thread thread1 : threads){
      if(thread1 != null && thread1.getName().contains("Standard")){
          Field field1 = thread1.getClass().getDeclaredField("target");
          field1.setAccessible(true);
          Runnable target = (Runnable)field1.get(thread1);

          Field field2 = target.getClass().getDeclaredField("this$0");
          field2.setAccessible(true);
          StandardEngine standardEngine = (StandardEngine)field2.get(target);

          StandardHost standardHost = (StandardHost) standardEngine.findChild("localhost");
          StandardContext standardContext = (StandardContext)standardHost.findChild("/valve");
      }
  }
  }
%>
<html>
<head>
    <title>Title</title>
</head>
<body>

</body>
</html>
