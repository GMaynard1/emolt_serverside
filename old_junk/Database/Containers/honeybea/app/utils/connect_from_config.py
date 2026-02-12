## Import a .yml MySQL database configuration and connect to the database
def db_connect_from_config(filename):
    import yaml
    import pymysql
    
    with open(filename,'r') as file:
        db_config=yaml.safe_load(file)
        
    host = db_config['Host']
    user = db_config['User']
    pw = db_config['Password']
    db = db_config['Database']
    port = db_config['Port']

    conn = pymysql.connect(
        host = host,
        user =  user,
        password = pw,
        db = db,
        port = port
        )
    
    return(conn)
