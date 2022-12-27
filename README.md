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