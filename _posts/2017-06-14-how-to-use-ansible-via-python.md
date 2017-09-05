---
ID: 63071
post_title: How to use Ansible via Python
author: Maciej Ruciński
post_excerpt: ""
layout: post
permalink: >
  https://3mdeb.com/app-dev/how-to-use-ansible-via-python/
published: true
post_date: 2017-06-14 12:00:00
tags:
  - Python
  - Ansible
categories:
  - App Dev
---
![alt text](https://cub.nobleprog.com/sites/hitramx/files/styles/height50_scale/public/category_image/cursos-de-ansible-en-mexico.png?itok=xPUrGNrA)

**_Ansible is designed around the way people work and the way people work together_**

## What is Ansible

Ansible is simple IT engine for automation, it is designed for manage many
systems, rather than just one at a time. Ansible automates cloud provisioning,
configuration management, application deployment, intra-service
orchestration, and many other IT operations. It is easy to deploy due to using
no agents and no additional custom security infrastructure. We can define own
configuration management in simple YAML language, which is named
ansible-playbook. YAML is easier to read and write by humans than other common
data formats like XML or JSON. Futhermore, most programming languages contain
libraries which operate and work YAML.

## Inventory

Ansible works collaterally on many systems in your infrastructure, so it is
important to specify a roster to keep `hosts`. This list is named `inventory`,
which can be in one of many formats. For this example, the format is an
`INI-like` and is saved in `/etc/ansible/hosts`. 

```ini
mail.example.com

[webservers]
foo.example.com
bar.example.com

[dbservers]
one.example.com
two.example.com
three.example.com
```

## Ansible Playbook

Playbook is the way to direct systems, which is particularly powerful, compact
and easy to read and write. As we said configuration multi-system management is
formatted in YAML language. Ansible playbook consists of `plays`, which
contain `hosts` we would like to manage, and `tasks` we want to perform.

```yaml
---
- hosts: webservers
  vars:
    http_port: 80
    max_clients: 200
  remote_user: root
  tasks:
  - name: ensure apache is at the latest version
    yum: name=httpd state=latest
  - name: write the apache config file
    template: src=/srv/httpd.j2 dest=/etc/httpd.conf
    notify:
    - restart apache
  - name: ensure apache is running (and enable it at boot)
    service: name=httpd state=started enabled=yes
  handlers:
    - name: restart apache
      service: name=httpd state=restarted
```

### Ansible for Embedded Linux

> Note: This paragraph is relevant to Yocto build system

There is possibility to need build image with custom Linux-based system for
embedded with Ansible, using complete development environment, with tools,
metadata and documentation, named Yocto. In addition, we would like to run
ansible-playbook via python. It seems to be hard to implement. Nothing more
simple! It is needed to add recipe to image with ansible from
[Python Ansible package](https://github.com/OverC/meta-overc/blob/master/meta-cube/recipes-devtools/python/python-ansible_2.1.1.0.bb)

#### Additional information

For more information go to [Ansible Documentation](http://docs.ansible.com/ansible/)

## Python API

Python API is very powerful, so we can manage and run ansible-playbook from
python level, there is possibility to control nodes, write various plugins,
extend Ansible to respond to various python events and plug in inventory data
from external data sources.

> Note: There is a permament structure to build python program which operates
ansible commands:

First of all we have to import some modules needed to run ansible in python.

- Let's describe some of them:

  - `json` module to convert output to json format
  - `ansible` module to manage e.g. inventory or plays
  - `TaskQueueManager` is responsible for loading the play strategy plugin,
  which dispatches the Play's tasks to hosts
  - `CallbackBase` module - base ansible callback class, that does nothing
  here, but new callbacks, which inherits from CallbackBase class and
  override methods, can execute custom actions

```python
import json
from collections import namedtuple
from ansible.parsing.dataloader import DataLoader
from ansible.vars import VariableManager
from ansible.inventory import Inventory
from ansible.playbook.play import Play
from ansible.executor.task_queue_manager import TaskQueueManager
from ansible.plugins.callback import CallbackBase
```

- ResultCallback which inherits from `CallbackBase` and manage the output of
ansible. We can create and modify own methods to regulate the
behaviour of the ansbile in python controller.

```python
class ResultCallback(CallbackBase):

  def v2_runner_on_ok(self, result, **kwargs):
    host = result._host
    print json.dumps({host.name: result._result}, indent=4)
```

> Note: we can override more methods. All specification can be found in
[CallbackBase](https://github.com/ansible/ansible/blob/devel/lib/ansible/plugins/callback/__init__.py)

- Next step is to initialize needed objects. Options class to replace Ansible
OptParser. Since we're not calling it via CLI, we need something to provide
options.

```python
Options = namedtuple(&#039;Options&#039;, [&#039;connection&#039;, &#039;module_path&#039;, &#039;forks&#039;, &#039;become&#039;, &#039;become_method&#039;, &#039;become_user&#039;, &#039;check&#039;])
variable_manager = VariableManager()
loader = DataLoader()
options = Options(connection=&#039;local&#039;, module_path=&#039;/path/to/mymodules&#039;, forks=100, become=None, become_method=None, become_user=None, check=False)
passwords = dict(vault_pass=&#039;secret&#039;)
```

- Instantiate our `ResultCallback` for handling results as they come in

```python
results_callback = ResultCallback()
```

- Then the script creates a VariableManager object, which is responsible for
adding in all variables from the various sources, and keeping variable
precedence consistent. Then create play with tasks - basic jobs we want to
handle by ansible.

```python
inventory = Inventory(loader=loader, variable_manager=variable_manager, host_list=&#039;localhost&#039;)
variable_manager.set_inventory(inventory)
```

```python
play_source =  dict(
        name = &quot;Ansible Play&quot;,
        hosts = &#039;localhost&#039;,
        gather_facts = &#039;no&#039;,
        tasks = [
            dict(action=dict(module=&#039;shell&#039;, args=&#039;ls&#039;), register=&#039;shell_out&#039;),
            dict(action=dict(module=&#039;debug&#039;, args=dict(msg=&#039;{{shell_out.stdout}}&#039;)))
         ]
    )
play = Play().load(play_source, variable_manager=variable_manager, loader=loader)
```

- Actually run it, using the `Runner` object for collecting needed data and
running the Ansible Playbook executor. The actual execution of the playbook is
in a run method, so we can call it when we need to. The `__init__` method just
sets everything up for us. This should run your roles against your hosts! It
will still output the usual data to Stderr/Stdout.

```python
tqm = None
try:
    tqm = TaskQueueManager(
              inventory=inventory,
              variable_manager=variable_manager,
              loader=loader,
              options=options,
              passwords=passwords,
              stdout_callback=results_callback,  # Use our custom callback instead of the ``default`` callback plugin
          )
    result = tqm.run(play)
finally:
    if tqm is not None:
        tqm.cleanup()
```

## Conclusion

Ansible delivers IT automation that ends repetitive tasks and frees up DevOps
teams for more strategic work. Manage the Ansbile via Python API is easy, it
can be applied to operate a configuration on many systems at the time, using
only simple python program. 

## Summary

We hope you enjoyed this post. If you have any comments please leave it below,
if you think this post provide valuable information please share with
interested parties.

We are always open for leveraging Ansible and Python in IoT and embedded
environment. If you have project that can benefit from those IT automation do
not hesitate to drop us email `contact<at>3mdeb.com`.