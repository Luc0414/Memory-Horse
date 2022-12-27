package com.controller.controller.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class demoController {
    @GetMapping("/demo")
    public String demo(){
        return "Demo test page";
    }
}
