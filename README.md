# 内存马学习笔记

## 一.获取StandardContext

### 1.从contextClassLoader获取

由于Tomcat处理请求线程中，存在ContextLoader对象，而该对象又保存了StandardContext对象，所有可以通过线程来获取到StandardContext；
```jsp
    WebappClassLoaderBase webappClassLoaderBase =(WebappClassLoaderBase) Thread.currentThread().getContextClassLoader();

    Field field =  WebappClassLoaderBase.class.getDeclaredField("resources");
    field.setAccessible(true);
    WebResourceRoot webResourceRoot = (WebResourceRoot)field.get(webappClassLoaderBase);
    StandardContext standardContext = (StandardContext)webResourceRoot.getContext();

    response.getWriter().write(standardContext.getPath());
```
这里之所以不用getResources来获取Resources是因为该方法在后面的版本中已经弃用，可以改用反射的方法来获取到该变量。
```java
@Deprecated
public WebResourceRoot getResources() {
    return null;
}
```
该方法限制于Tomcat8/9

### 2.从线程获取
```jsp
<%
  java.lang.ThreadGroup threadGroup = (java.lang.ThreadGroup)Thread.currentThread().getThreadGroup();
  Field field = threadGroup.getClass().getDeclaredField("threads");
  field.setAccessible(true);
  Thread[] threads = (Thread[])field.get(threadGroup);
  for (Thread thread : threads) {
      if(thread != null && thread.getName().contains("Standard")){
          Field field1 = thread.getClass().getDeclaredField("target");
          field1.setAccessible(true);
          Runnable target = (Runnable)field1.get(thread);

          Field field2 = target.getClass().getDeclaredField("this$0");
          field2.setAccessible(true);
          StandardEngine standardEngine = (StandardEngine)field2.get(target);

          StandardHost standardHost = (StandardHost) standardEngine.findChild("localhost");
          StandardContext standardContext = (StandardContext)standardHost.findChild("/valve");
          System.out.println(standardContext);
      }

  }
%>
```
