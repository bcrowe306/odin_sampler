package cairo


import "core:fmt"
import "core:container/queue"

RouterStackCommand :: enum {
    None,
    PushPage,
    PopPage,
    SwitchPage,
}

PageSwitchCommand :: struct {
    name: string,
    command: RouterStackCommand,
    data: any,
    
}

resetPageSwitchCommnand :: proc(router: ^Router) {
    router.next_page.command = RouterStackCommand.None
    router.next_page.name = ""
    router.next_page.data = nil
}

Router :: struct {
    pages: map[string]^PageWidget,
    stack: queue.Queue(string),
    next_page: PageSwitchCommand,
    
    // Methods
    addPage: proc(router: ^Router, page: ^PageWidget),
    getCurrentPage: proc(router: ^Router) -> ^PageWidget,
    processPageSwitch: proc(router: ^Router) -> bool,
    push : proc(router: ^Router, page_name: string, data: any = nil),
    pop : proc(router: ^Router, data: any = nil),
    swap : proc(router: ^Router, page_name: string, data: any = nil),
}

createRouter :: proc() -> ^Router {
    router := new(Router)
    router.pages = make(map[string]^PageWidget)
    router.stack = queue.Queue(string){}
    router.addPage = addPageToRouter
    router.getCurrentPage = getCurrentRouterPage
    router.processPageSwitch = processRouterPageSwitch
    router.push = pushPage
    router.pop = popPage
    router.swap = swapPage
    router.next_page = PageSwitchCommand{}
    resetPageSwitchCommnand(router)

    return router
}

addPageToRouter :: proc(router: ^Router, page: ^PageWidget) {
    router.pages[page.name] = page
    if queue.len(router.stack) == 0 {
        router.next_page = PageSwitchCommand{name= page.name, command= RouterStackCommand.PushPage}
    }
}

pushPage :: proc(router: ^Router, page_name: string, data: any = nil) {
    router.next_page = PageSwitchCommand{name= page_name, command= RouterStackCommand.PushPage, data= data}
}

popPage :: proc(router: ^Router, data: any = nil) {
    router.next_page = PageSwitchCommand{command= RouterStackCommand.PopPage, data= data}
}

swapPage :: proc(router: ^Router, page_name: string, data: any = nil) {
    router.next_page = PageSwitchCommand{name= page_name, command= RouterStackCommand.SwitchPage, data= data}
}

beforeNav :: proc (router: ^Router, current_page: ^PageWidget, next_page: ^PageWidget) {

    if current_page != nil && current_page.beforeLeave != nil {
        current_page.beforeLeave(current_page)
    }
    if next_page.beforeLoad != nil {
        next_page.beforeLoad(next_page)
    }
    
}

afterNav :: proc (router: ^Router, current_page: ^PageWidget, next_page: ^PageWidget, data: any) {
    if current_page != nil && current_page.afterLeave != nil {
        current_page.afterLeave(current_page)
    }
    if next_page.afterLoad != nil {
        next_page.afterLoad(next_page, data)
    }
}


processRouterPageSwitch :: proc(router: ^Router) -> bool{
    switch router.next_page.command {
        case RouterStackCommand.PushPage:
            if page, exists := router.pages[router.next_page.name]; exists {
                current_page := router->getCurrentPage()
                next_page := router.pages[router.next_page.name]

                if next_page != nil {
                    if current_page != nil && current_page.name == next_page.name {
                        resetPageSwitchCommnand(router)
                        return false
                    }
                    beforeNav(router, current_page, next_page)
                    queue.push_back(&router.stack, router.next_page.name)
                    afterNav(router, current_page, next_page, router.next_page.data)
                    resetPageSwitchCommnand(router)
                    return true
                }
                else {
                    fmt.println("Router: Attempted to push non-existent page: ", router.next_page.name)
                    return false
                }
            }
            else {
                fmt.println("Router: Attempted to push non-existent page: ", router.next_page.name)
                return false
            }
        case RouterStackCommand.PopPage:
            if queue.len(router.stack) > 0 {
                current_page := router->getCurrentPage()
                queue.pop_back(&router.stack)
                next_page := router->getCurrentPage()

                if current_page != nil && next_page != nil && current_page.name != next_page.name {
                    beforeNav(router, current_page, next_page)
                    afterNav(router, current_page, next_page, router.next_page.data)
                    resetPageSwitchCommnand(router)
                    return true
                } else {
                    fmt.println("Router: No page to pop to or popped to the same page")
                    return false
                }
                
            }
            else {
                fmt.println("Router: Attempted to pop page from empty stack")
                return false
            }
        case RouterStackCommand.SwitchPage:
            if page, exists := router.pages[router.next_page.name]; exists {
                current_page := router->getCurrentPage()
                next_page := router.pages[router.next_page.name]
                if current_page != nil && next_page != nil && current_page.name != next_page.name {
                    beforeNav(router, current_page, next_page)
                    queue.pop_back(&router.stack)
                    queue.push_back(&router.stack, router.next_page.name)
                    afterNav(router, current_page, next_page, router.next_page.data)
                    resetPageSwitchCommnand(router)
                    return true
                } else {
                    fmt.println("Router: No page to switch to or switched to the same page")
                    return false
                }
            }
            else {
                fmt.println("Router: Attempted to switch to non-existent page: ", router.next_page.name)
                return false
            }
        case RouterStackCommand.None:
            return false
    }
    return false  
}

getCurrentRouterPage :: proc(router: ^Router) -> ^PageWidget {
    if queue.len(router.stack) == 0 {
        return nil
    }
    page_name := queue.back(&router.stack)
    if page, exists := router.pages[page_name]; exists {
        return page
    }
    return nil
}

getCurrentPageName :: proc(router: ^Router) -> string {
    page_name := queue.back(&router.stack)
    return page_name
}
