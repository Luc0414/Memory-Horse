package com.controller.controller.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.WebApplicationContext;

import javax.servlet.http.HttpServletRequest;

@RestController
public class demoController {
    @GetMapping("/demo")
    public String demo(HttpServletRequest request){
        System.out.println(request);
        WebApplicationContext webApplicationContext = (WebApplicationContext)request.getAttribute("org.springframework.web.servlet.DispatcherServlet.CONTEXT");
        return "Demo test page";
    }
}
