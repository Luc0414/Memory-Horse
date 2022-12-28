package com.controller.controller.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;
import org.springframework.web.servlet.support.RequestContextUtils;

@RestController
public class inject {
    String code;
    @GetMapping("/inject")
    public String inject(){
        final String controllerpath = "/Wh0Am1";
        WebApplicationContext context = RequestContextUtils.findWebApplicationContext(((ServletRequestAttributes) RequestContextHolder.currentRequestAttributes()).getRequest());
        RequestMappingHandlerMapping mapping = context.getBean(RequestMappingHandlerMapping.class);



        return "inject test page";
    }

    @GetMapping("/test")
    public String test(){
        return "test";
    }
}
