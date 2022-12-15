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
